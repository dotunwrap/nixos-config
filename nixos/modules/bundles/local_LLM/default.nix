_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.bundles.local_LLM;

  # With the router on, it owns the public port and each unit sits on port + its offset.
  portFor = offset: if cfg.router.enable then cfg.port + offset else cfg.port;

  # vLLM profiles free VRAM once, at startup. Switching models stops one unit and starts another
  # while the first is still releasing its memory, and a start in that window sizes a KV pool
  # about 40% too small without any error. So each unit waits until every card is nearly empty
  # (under 1 GB used, up to two minutes) before it starts. Checks all cards, not just the first.
  waitGpuFree = pkgs.writeShellScript "local-llm-wait-gpu-free" ''
    smi=${config.hardware.nvidia.package.bin}/bin/nvidia-smi
    for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
      # An nvidia-smi failure or empty output is "unknown", not "free": keep waiting.
      busiest=$($smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null \
        | ${pkgs.coreutils}/bin/sort -n | ${pkgs.coreutils}/bin/tail -n 1)
      [ -n "$busiest" ] && [ "$busiest" -lt 1000 ] && exit 0
      ${pkgs.coreutils}/bin/sleep 2
    done
    echo "local-llm: GPU memory still in use after 120s, starting anyway" >&2
  '';

  unitNames = lib.attrNames cfg.units;
  othersOf = unit: map (u: "${u}.service") (lib.remove unit unitNames);

  # llama-swap runs this as the model's process: it starts the unit, stays alive while the
  # unit is up (so a crash looks like one to llama-swap) and stops the unit on SIGTERM.
  # systemctl needs no sudo here: see the polkit rule below.
  systemctl = "${config.systemd.package}/bin/systemctl";
  runUnit =
    unit:
    pkgs.writeShellScript "local-llm-run-${unit}" ''
      set -u
      trap '${systemctl} stop ${unit}.service; exit 0' TERM INT
      ${systemctl} start ${unit}.service || exit 1
      while ${systemctl} is-active --quiet ${unit}.service; do
        sleep 5 &
        wait $!
      done
      exit 1
    '';

  routerConfig = (pkgs.formats.yaml { }).generate "local-llm-router.yaml" {
    # A cold start compiles kernels, captures CUDA graphs or loads a whole model: minutes.
    healthCheckTimeout = 1500;
    # While a backend starts, stream status into the response's reasoning_content so clients like
    # Pi show progress instead of waiting silently. Streaming requests only.
    sendLoadingState = true;
    models = lib.mapAttrs' (
      unit: u:
      lib.nameValuePair u.routerName {
        cmd = "${runUnit unit}";
        proxy = "http://127.0.0.1:${toString (portFor u.portOffset)}";
        checkEndpoint = "/v1/models";
        inherit (u) useModelName;
        # Stays loaded until another model is requested.
        ttl = 0;
      }
    ) cfg.units;
  };
in
{
  # Backends: each registers its units in `bundles.local_LLM.units` and defines them.
  imports = [
    ./hyperqwen
    ./strata
  ];

  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle: model servers that share the GPUs, one at a time.";

    user = lib.mkOption {
      type = lib.types.str;
      default = "nia";
      description = "User the servers run as. It owns their installs, model files and caches.";
    };

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the servers (or the router) bind to. There is no API key, so anything other than
        loopback relies on the firewall, which here trusts only Tailscale.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18020;
      description = ''
        Port clients use: the router's when `router.enable` is set, otherwise the server's. Behind
        the router the units listen on this port plus their offset.
      '';
    };

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start a server at boot: the router when it is on, otherwise the default backend's first
        unit. The units conflict over the GPUs, so starting one stops the others.
      '';
    };

    router.enable = lib.mkEnableOption ''
      a llama-swap router (`local-llm-router.service`) on `port` that lists every enabled model
      and swaps the GPUs to whichever one a request names. The units then listen on port+1 and up,
      and the router starts at boot instead of them
    '';

    units = lib.mkOption {
      internal = true;
      default = { };
      description = "Units the backends define, keyed by systemd unit name. Set by the backends.";
      type = lib.types.attrsOf (
        lib.types.submodule {
          options = {
            routerName = lib.mkOption {
              type = lib.types.str;
              description = "Model name the router lists the unit under.";
            };
            portOffset = lib.mkOption {
              type = lib.types.ints.positive;
              description = "Port offset from `port` behind the router.";
            };
            useModelName = lib.mkOption {
              type = lib.types.str;
              description = "API name the server answers to, whatever name the client asked for.";
            };
            autostart = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Whether this unit starts at boot when there is no router.";
            };
          };
        }
      );
    };
  };

  config = lib.mkMerge [
    # What the backends need from this layer.
    { _module.args.localLLM = { inherit portFor waitGpuFree; }; }

    (lib.mkIf cfg.enable {
      # One unit per model: they share the GPUs (and the port without the router), so each
      # conflicts with the others and starting one stops the rest.
      systemd.services = lib.mapAttrs (unit: u: {
        after = [ "network.target" ];
        conflicts = othersOf unit;
        wantedBy = lib.optional (cfg.autostart && !cfg.router.enable && u.autostart) "multi-user.target";
      }) cfg.units;

      # Passwordless control of just these services, so benchmarking can restart them without a
      # terminal. Deliberately excludes nixos-rebuild.
      security.sudo.extraRules = [
        {
          users = [ cfg.user ];
          commands =
            map
              (cmd: {
                command = "/run/current-system/sw/bin/systemctl ${cmd}";
                options = [ "NOPASSWD" ];
              })
              (
                lib.concatMap (action: map (unit: "${action} ${unit}.service") unitNames) [
                  "start"
                  "stop"
                  "restart"
                ]
              );
        }
      ];
    })

    (lib.mkIf (cfg.enable && cfg.router.enable) {
      systemd.services.local-llm-router = {
        description = "llama-swap router for the local LLM servers";
        wantedBy = lib.optional cfg.autostart "multi-user.target";
        after = [ "network.target" ];
        serviceConfig = {
          User = cfg.user;
          ExecStart = "${lib.getExe pkgs.llama-swap} --config ${routerConfig} --listen ${cfg.host}:${toString cfg.port}";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      # The router's wrapper scripts start and stop the units as the service user, not through
      # sudo (the service has no setuid).
      security.polkit = {
        enable = true;
        extraConfig = ''
          polkit.addRule(function(action, subject) {
            if (action.id == "org.freedesktop.systemd1.manage-units" &&
                subject.user == "${cfg.user}" &&
                ${builtins.toJSON (map (u: "${u}.service") unitNames)}.indexOf(action.lookup("unit")) >= 0) {
              return polkit.Result.YES;
            }
          });
        '';
      };
    })
  ];
}
