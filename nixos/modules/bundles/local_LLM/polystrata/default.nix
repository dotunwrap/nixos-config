{
  config,
  lib,
  pkgs,
  localLLM,
  ...
}:
let
  llm = config.bundles.local_LLM;
  cfg = llm.polystrata;

  home = "/home/${llm.user}";
  polystrata = pkgs.callPackage ./package.nix { };

  # Where the files Nix does not own go: the model (17 GB, see `fetch` below), the tokenizer pack
  # derived from it, the expert profile the engine writes back, and the engine's log.
  state = "${home}/.local/state/polystrata";
  models = "${home}/models/ornith-1.5";
  gguf = "${models}/Ornith-1.5-35B-A3B-APEX-MTP-I-Compact.gguf";
  mmproj = "${models}/mmproj.gguf";
  pack = "${state}/ornith-pack";

  modelName = "ornith-1.5-35b-a3b-apex-i-compact";

  # What setup.py would write to strata-ornith-apex-i-compact.json, with the store paths filled in.
  launchConfig = pkgs.writeText "polystrata-ornith.json" (
    builtins.toJSON (
      {
        exe = "${polystrata}/bin/strata-poly";
        args = [
          "--model"
          gguf
          "--max-context"
          (toString cfg.contextSize)
          "--expert-profile"
          "${state}/ornith-expert-profile.txt"
          # RAM to park other conversations in (agents send several in turn); setup's default.
          "--conversation-cache-mib"
          "auto"
        ]
        ++ cfg.extraArgs;
        cwd = state;
        tokenizer = "${pack}/tokenizer";
        model_name = modelName;
        display_name = "Ornith 1.5 35B-A3B APEX-I-COMPACT";
        log = "${state}/ornith.engine.log";
        # autoAddDriverRunpath gives the engine libcuda.
        lib_dirs = [ ];
        # Split the layers over both cards; the server puts the faster one last.
        gpu = [
          0
          1
        ];
        gpus_asked = true;
        layer_split = "auto";
        host = "127.0.0.1";
        open_browser = false;
        # llama-swap passes the client's Host header through, and PolyStrata refuses names it does
        # not know (DNS-rebinding check): `http://dosei:18020` would be a 403 without this.
        allowed_hosts = cfg.allowedHosts;
      }
      // lib.optionalAttrs cfg.vision {
        vision = {
          exe = "${polystrata}/bin/strata-vision";
          inherit mmproj;
          model = gguf;
          gpu = false;
          max_tokens = 300;
          threads = 8;
        };
      }
    )
  );

  # Downloads the model files the unit reads (not run by the unit: 17 GB would outlast the router's
  # health-check timeout). Resumable, and checked against the SHA-256 setup.py pins.
  fetch = pkgs.writeShellApplication {
    name = "polystrata-fetch-ornith";
    runtimeInputs = with pkgs; [
      curl
      coreutils
    ];
    text = ''
      base=https://huggingface.co/mudler/Ornith-1.5-35B-A3B-APEX-MTP-GGUF/resolve/main
      dir=${models}
      mkdir -p "$dir"
      get() {
        name=$1 sha=$2
        [ -f "$dir/$name" ] && [ "$(sha256sum "$dir/$name" | cut -d' ' -f1)" = "$sha" ] && { echo "$name ok"; return; }
        curl -fL -C - --retry 5 -o "$dir/$name" "$base/$name"
        echo "$sha  $dir/$name" | sha256sum -c -
      }
      get Ornith-1.5-35B-A3B-APEX-MTP-I-Compact.gguf 67e6cdff678e67180d3cd4eef55277277563319057de287b8855c4d1fbff4165
      ${lib.optionalString cfg.vision ''
        get mmproj.gguf e277123529451fbcff6d880ad5bd7ada999f9d5e6339ba3639d06c5cef4763b1
      ''}
    '';
  };

  start = pkgs.writeShellScript "polystrata-ornith-start" ''
    set -eu
    mkdir -p ${state}
    for f in ${gguf} ${lib.optionalString cfg.vision mmproj}; do
      [ -f "$f" ] || { echo "polystrata: $f is missing: run polystrata-fetch-ornith" >&2; exit 1; }
    done
    # The tokenizer comes out of the model's own metadata; this reads the header only.
    if [ ! -f ${pack}/tokenizer/vocab.json ]; then
      ${polystrata}/bin/polystrata-tokenizer --gguf ${gguf} --out ${pack}
    fi
    exec ${polystrata}/bin/polystrata-server --engine strata \
      --config ${launchConfig} --host ${llm.host} --port ${toString (localLLM.portFor 6)}
  '';
in
{
  options.bundles.local_LLM.polystrata = {
    enable = lib.mkEnableOption ''
      PolyStrata serving Ornith 1.5 35B-A3B (APEX-I-COMPACT, its own MTP draft block) on the
      strata-poly engine, listed by the router as `polystrata-ornith`. Run
      `polystrata-fetch-ornith` once to download the model (about 18 GB)
    '';

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 131072;
      description = ''
        Maximum context (--max-context). Each token takes about 26 KB of VRAM, so 128K costs
        2.6 GB more than 32K, which comes out of the GPU expert cache.
      '';
    };

    vision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Let the model read images: mmproj.gguf (0.9 GB) and a CPU picture reader.";
    };

    allowedHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ config.networking.hostName ];
      description = ''
        Host names clients reach the router by, which PolyStrata would otherwise refuse (403).
        Names only, no ports; `"*"` turns the check off.
      '';
    };

    extraArgs = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "More arguments for strata-poly, e.g. --kv q8_0 or --vram-reserve-mib N.";
    };
  };

  config = lib.mkIf (llm.enable && cfg.enable) {
    environment.systemPackages = [ fetch ];

    bundles.local_LLM.units.polystrata = {
      routerName = "polystrata-ornith";
      portOffset = 6;
      useModelName = modelName;
      inherit (cfg) contextSize vision;
      # /v1/models answers (empty) while the engine is still loading; /health only says "loaded"
      # once it is.
      checkEndpoint = "/health";
    };

    systemd.services.polystrata = {
      description = "PolyStrata server (Ornith 1.5 35B-A3B APEX-I-COMPACT)";
      environment.HOME = home;
      serviceConfig = {
        User = llm.user;
        ExecStartPre = "${localLLM.waitGpuFree}";
        ExecStart = "${start}";
        TimeoutStartSec = "30min";
        TimeoutStopSec = "90s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };
  };
}
