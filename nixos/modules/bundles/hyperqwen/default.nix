_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.bundles.hyperqwen;

  # HyperQwen's venv holds pip wheels (torch, nvcc, FlashInfer) that need an FHS loader, and
  # Triton compiles small C launchers at runtime, so the server runs inside an FHS env with gcc.
  # gcc 15 on purpose: nvcc 13.0 rejects gcc 16. Everything here is free software, unlike steam-run.
  fhs = pkgs.buildFHSEnv {
    name = "hyperqwen-fhs";
    targetPkgs =
      p: with p; [
        gcc15
        git
        openssl
        zlib
        stdenv.cc.cc.lib
        numactl
        bash
        coreutils
      ];
    runScript = "bash";
  };

  # Bigger env for hyperqwen-setup only: adds the build tools the install scripts call (patch for
  # the vLLM series, cmake/ninja for xgrammar, uv for the venv) so the service's closure stays small.
  setupFhs = pkgs.buildFHSEnv {
    name = "hyperqwen-setup-fhs";
    targetPkgs =
      p: with p; [
        gcc15
        git
        openssl
        zlib
        stdenv.cc.cc.lib
        numactl
        bash
        coreutils
        uv
        patch
        diffutils
        findutils
        gnugrep
        gnused
        gawk
        gnumake
        cmake
        ninja
        pkg-config
        which
        curl
      ];
    runScript = "bash";
  };

  # `hyperqwen-setup` builds or updates the environment the service runs from. The gcc-ar and
  # gcc-ranlib paths are the unwrapped gcc 15's: see the xgrammar step in setup.sh.
  setup = pkgs.writeShellScriptBin "hyperqwen-setup" ''
    export HQ_REPO="''${HQ_REPO:-${cfg.repoPath}}"
    export HQ_REV="''${HQ_REV-${cfg.repoRev}}"
    export HQ_GCC_AR=${pkgs.gcc15.cc}/bin/gcc-ar
    export HQ_GCC_RANLIB=${pkgs.gcc15.cc}/bin/gcc-ranlib
    # The FHS env replaces /etc, so bwrap can't start from a cwd under it (e.g. /etc/nixos).
    cd "''${HOME:-/}"
    exec ${setupFhs}/bin/hyperqwen-setup-fhs ${./setup.sh} "$@"
  '';

  # Directories under `repoPath/models`. Null leaves the choice to the launcher, which serves
  # the Qwen fast variant that `hyperqwen-setup` builds. `hyperqwen-setup` fetches swift too.
  modelDirs = {
    qwen = null;
    swift = "Swift-1.5-Qwen3.8-27B-W4A16-HyperQwen-INT4";
    # The same Swift 1.5 checkpoint with the CJK tokens removed, so it answers in English only.
    swiftEnglish = "Swift-1.5-Qwen3.8-27B-W4A16-HyperQwen-INT4-noCJK";
    # Swift with the refusal direction ablated (ultimaterex's AutoRound W4A16, int4 heads and MTP
    # included). `HQ_STEPS=+uncensored hyperqwen-setup` downloads it (about 16GB).
    swiftUncensored = "Swift-Qwen3.8-27B-Uncensored-W4A16-AutoRound";
  };

  start = pkgs.writeShellScript "hyperqwen-start" ''
    set -eu
    mkdir -p "$TMPDIR"
    export CC=gcc CXX=g++
    cd ${lib.escapeShellArg cfg.repoPath}
    exec bash single-user/start_qwen.sh
  '';

  # vLLM profiles free VRAM once, at startup. Switching models stops one unit and starts another
  # while the first is still releasing its memory, and a start in that window sizes a KV pool
  # about 40% too small without any error. So each unit waits until every card is nearly empty
  # (under 1 GB used, up to two minutes) before it starts. Checks all cards, not just the first.
  waitGpuFree = pkgs.writeShellScript "hyperqwen-wait-gpu-free" ''
    smi=${config.hardware.nvidia.package.bin}/bin/nvidia-smi
    for _ in $(${pkgs.coreutils}/bin/seq 1 60); do
      busiest=$($smi --query-gpu=memory.used --format=csv,noheader,nounits 2>/dev/null \
        | ${pkgs.coreutils}/bin/sort -n | ${pkgs.coreutils}/bin/tail -n 1)
      [ "''${busiest:-0}" -lt 1000 ] && exit 0
      ${pkgs.coreutils}/bin/sleep 2
    done
    echo "hyperqwen: GPU memory still in use after 120s, starting anyway" >&2
  '';

  # One unit per model: they share the port and the GPUs, so each conflicts with the others
  # (and llama-cpp) and starting one stops the rest.
  mkService =
    {
      model,
      description,
      autostart,
      others,
      port,
    }:
    {
      inherit description;
      wantedBy = lib.optional autostart "multi-user.target";
      after = [
        "network.target"
        "llama-cpp.service"
      ];
      conflicts = [ "llama-cpp.service" ] ++ others;

      environment = {
        HOME = "/home/${cfg.user}";
        TMPDIR = "/var/tmp/hyperqwen";
        HOST = cfg.host;
        PORT = toString port;
        SPEC = cfg.speculation;
        CTX = cfg.contextMode;
        MAX_LEN = toString cfg.contextSize;
        GPU_UTIL = cfg.gpuMemoryUtilization;
        MAX_SEQS = toString cfg.maxSeqs;
        PREFIX_CACHE = "1";
        # Numbers CUDA devices by PCI bus so device order matches nvidia-smi on mixed cards.
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";
        # NCCL_PROTO is deliberately not set. It was LL, which suits small messages, but on this
        # pair (no peer-to-peer, all-reduce through host memory) it held prefill at about 930 tok/s;
        # letting NCCL choose (or Simple) gave about 1,320, with decode unchanged within noise.
        EXTRA_ARGS = "--tensor-parallel-size ${toString cfg.tensorParallelSize}";
      }
      // lib.optionalAttrs (cfg.contextMode == "long" && cfg.speculation == "mtp") { PTH_FA = "1"; }
      // lib.optionalAttrs (cfg.contextMode == "long" && cfg.speculation == "dflash2") {
        FA2_FP8KV = "0";
      }
      // lib.optionalAttrs cfg.vision {
        VISION = "1";
        VISION_OFFLOAD = "1";
      }
      // lib.optionalAttrs (modelDirs.${model} != null) {
        MODEL = "${cfg.repoPath}/models/${modelDirs.${model}}";
      }
      // cfg.extraEnvironment;

      serviceConfig = {
        User = cfg.user;
        ExecStartPre = "${waitGpuFree}";
        ExecStart = "${fhs}/bin/hyperqwen-fhs ${start}";
        # First start compiles kernels and captures CUDA graphs; a cold cache takes minutes.
        TimeoutStartSec = "20min";
        TimeoutStopSec = "60s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };
  # With the router on, it owns the public port and the units sit on the next three.
  qwenPort = cfg.port + 1;
  swiftPort = cfg.port + 2;
  swiftEnglishPort = cfg.port + 3;
  swiftUncensoredPort = cfg.port + 4;

  # llama-swap runs this as the model's process: it starts the unit, stays alive while the
  # unit is up (so a crash looks like one to llama-swap) and stops the unit on SIGTERM.
  # systemctl needs no sudo here: see the polkit rule below.
  systemctl = "${config.systemd.package}/bin/systemctl";
  runUnit =
    unit:
    pkgs.writeShellScript "hyperqwen-run-${unit}" ''
      set -u
      trap '${systemctl} stop ${unit}.service; exit 0' TERM INT
      ${systemctl} start ${unit}.service || exit 1
      while ${systemctl} is-active --quiet ${unit}.service; do
        sleep 5 &
        wait $!
      done
      exit 1
    '';

  routerModel = unit: port: {
    cmd = "${runUnit unit}";
    proxy = "http://127.0.0.1:${toString port}";
    checkEndpoint = "/v1/models";
    # Both launchers serve the API name `qwen3.8-27b`, whatever name the client asked for.
    useModelName = "qwen3.8-27b";
    # Stays loaded until another model is requested.
    ttl = 0;
  };

  routerConfig = (pkgs.formats.yaml { }).generate "hyperqwen-router.yaml" {
    # A cold start compiles kernels and captures CUDA graphs: minutes.
    healthCheckTimeout = 1500;
    models = {
      "qwen3.8-27b" = routerModel "hyperqwen" qwenPort;
      "swift-1.5" = routerModel "hyperqwen-swift" swiftPort;
      "swift-1.5-english" = routerModel "hyperqwen-swift-english" swiftEnglishPort;
      "swift-uncensored" = routerModel "hyperqwen-swift-uncensored" swiftUncensoredPort;
    };
  };
in
{
  options.bundles.hyperqwen = {
    enable = lib.mkEnableOption "HyperQwen, a patched vLLM server for Qwen3.8-27B (OpenAI-compatible).";

    autostart = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Start HyperQwen at boot. When set, llama-cpp stops starting at boot (it stays defined
        and `systemctl start llama-cpp` still works). The two units conflict over the GPUs, so
        starting either one stops the other.
      '';
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "nia";
      description = "User the server runs as. It owns the venv, the model files and the caches.";
    };

    repoPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/nia/Projects/HyperQwen";
      description = ''
        Checkout of syv-ai/HyperQwen with its venv and `models/`. Nix doesn't build these: run
        `hyperqwen-setup` once to create them, and again after a nixpkgs bump that changes the FHS
        env's gcc or glibc (it skips whatever is already done).
      '';
    };

    repoRev = lib.mkOption {
      type = lib.types.str;
      default = "3d6c9543292efc17372b824071ef8d9f33366b21";
      description = ''
        HyperQwen commit that `hyperqwen-setup` checks out. The vLLM patch series, the pinned
        pthfa and xgrammar sources and the launcher all come from this checkout, so bump it
        deliberately. Empty leaves the checkout wherever it is.
      '';
    };

    router.enable = lib.mkEnableOption ''
      a llama-swap router on `port` that lists the models (`qwen3.8-27b`, `swift-1.5`,
      `swift-1.5-english` and `swift-uncensored`) and swaps the GPUs to whichever one a request
      names. The units then listen on port+1 (default model), port+2 (Swift), port+3 (Swift,
      English only) and port+4 (Swift, uncensored), and the router starts at boot instead of them
    '';

    host = lib.mkOption {
      type = lib.types.str;
      default = "127.0.0.1";
      description = ''
        Address the server binds to. There is no API key (the launcher only enforces one when
        `api_key.txt` or VLLM_API_KEY exists), so anything other than loopback relies on the
        firewall, which here trusts only Tailscale.
      '';
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 18020;
      description = "Port the server listens on.";
    };

    model = lib.mkOption {
      type = lib.types.enum (builtins.attrNames modelDirs);
      default = "qwen";
      description = ''
        Model to serve, always under the API name `qwen3.8-27b`. `qwen` is the W4A16 AutoRound
        quant with the repo's int4 head and drafter. `swift` is Swift 1.5 (UkisAI's
        efficient-reasoning fine-tune of Qwen3.8-27B, under the Swift Open License) with int4
        heads, prepared for HyperQwen by daavidhauser. Switching needs the model on disk:
        `HQ_STEPS=+swift hyperqwen-setup` downloads swift (about 18GB).
      '';
    };

    speculation = lib.mkOption {
      type = lib.types.enum [
        "mtp"
        "dflash2"
      ];
      default = "mtp";
      description = ''
        Speculative decoding method. mtp was as fast as dflash2 on this rig with far more
        context, since dflash2's drafter and state pages cost a lot of the 12GB card's memory.
      '';
    };

    contextMode = lib.mkOption {
      type = lib.types.enum [
        "fast"
        "long"
        "huge"
      ];
      default = "long";
      description = ''
        KV cache profile (CTX). fast is bf16 KV, long is int8 KV read by the pth-flash-attn kernel
        (PTH_FA=1, built into the venv), and huge is the 4/2-bit KVarN cache (needs kvarn/install.sh).
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 150000;
      description = "Maximum context per request (MAX_LEN). The KV pool must hold at least this many tokens.";
    };

    gpuMemoryUtilization = lib.mkOption {
      type = lib.types.str;
      default = "0.92";
      description = "Fraction of each GPU's memory vLLM may use (GPU_UTIL). The 12GB card is the limit.";
    };

    maxSeqs = lib.mkOption {
      type = lib.types.int;
      default = 2;
      description = "Maximum concurrent requests (MAX_SEQS).";
    };

    tensorParallelSize = lib.mkOption {
      type = lib.types.enum [
        1
        2
        4
      ];
      default = 2;
      description = "GPUs the model is split over. The model does not fit on either card alone.";
    };

    vision = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = ''
        Serve images. The vision tower is only 0.86 GiB, and its weights stay in pinned host RAM
        (VISION_OFFLOAD), copied to the GPU for each image, so it costs about 1GiB of RAM and
        about 1% of the KV pool. Requests are limited to one image of at most ~2048 image tokens.
        Off by default: the server runs language-model-only, and images are rejected.
      '';
    };

    extraEnvironment = lib.mkOption {
      type = lib.types.attrsOf lib.types.str;
      default = { };
      example = {
        DFLASH_TOKENS = "7";
      };
      description = "Extra environment for the launcher, such as KV_MEM or EXTRA_ARGS overrides.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ setup ];

    systemd.services = {
      hyperqwen = mkService {
        inherit (cfg) model;
        description = "HyperQwen vLLM server";
        autostart = cfg.autostart && !cfg.router.enable;
        port = if cfg.router.enable then qwenPort else cfg.port;
        others = [
          "hyperqwen-swift.service"
          "hyperqwen-swift-english.service"
          "hyperqwen-swift-uncensored.service"
        ];
      };

      # Swift 1.5 beside the default model: started by hand, replacing hyperqwen.service until
      # that is started again. Both serve the API name `qwen3.8-27b`, so Hermes needs no change.
      hyperqwen-swift = mkService {
        model = "swift";
        description = "HyperQwen vLLM server (Swift 1.5)";
        autostart = false;
        port = if cfg.router.enable then swiftPort else cfg.port;
        others = [
          "hyperqwen.service"
          "hyperqwen-swift-english.service"
          "hyperqwen-swift-uncensored.service"
        ];
      };

      # The English-only Swift 1.5 (noCJK) as its own unit and, behind the router, its own model id,
      # `swift-1.5-english`. Same as the others: started on demand, and it replaces whichever is up.
      hyperqwen-swift-english = mkService {
        model = "swiftEnglish";
        description = "HyperQwen vLLM server (Swift 1.5, English only)";
        autostart = false;
        port = if cfg.router.enable then swiftEnglishPort else cfg.port;
        others = [
          "hyperqwen.service"
          "hyperqwen-swift.service"
          "hyperqwen-swift-uncensored.service"
        ];
      };

      # Swift with the refusal direction ablated, behind the router as `swift-uncensored`. Same
      # on-demand swap as the others.
      hyperqwen-swift-uncensored = mkService {
        model = "swiftUncensored";
        description = "HyperQwen vLLM server (Swift, uncensored)";
        autostart = false;
        port = if cfg.router.enable then swiftUncensoredPort else cfg.port;
        others = [
          "hyperqwen.service"
          "hyperqwen-swift.service"
          "hyperqwen-swift-english.service"
        ];
      };

      hyperqwen-router = lib.mkIf cfg.router.enable {
        description = "llama-swap router for HyperQwen";
        wantedBy = lib.optional cfg.autostart "multi-user.target";
        after = [ "network.target" ];
        serviceConfig = {
          User = cfg.user;
          ExecStart = "${lib.getExe pkgs.llama-swap} --config ${routerConfig} --listen ${cfg.host}:${toString cfg.port}";
          Restart = "on-failure";
          RestartSec = "10s";
        };
      };

      # llama-cpp and hyperqwen both claim the GPUs, so only one may start at boot.
      llama-cpp.wantedBy = lib.mkIf (cfg.autostart && config.services.llama-cpp.enable) (lib.mkForce [ ]);
    };

    # The router's wrapper scripts start and stop the units as the service user, not through sudo
    # (the service has no setuid).
    security.polkit = lib.mkIf cfg.router.enable {
      enable = true;
      extraConfig = ''
        polkit.addRule(function(action, subject) {
          if (action.id == "org.freedesktop.systemd1.manage-units" &&
              subject.user == "${cfg.user}" &&
              ["hyperqwen.service", "hyperqwen-swift.service", "hyperqwen-swift-english.service", "hyperqwen-swift-uncensored.service"].indexOf(action.lookup("unit")) >= 0) {
            return polkit.Result.YES;
          }
        });
      '';
    };

    # Passwordless control of just this service, mirroring llama-cpp, so benchmarking can
    # restart it without a terminal. Deliberately excludes nixos-rebuild.
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
              lib.concatMap
                (
                  action:
                  map (unit: "${action} ${unit}.service") [
                    "hyperqwen"
                    "hyperqwen-swift"
                    "hyperqwen-swift-english"
                    "hyperqwen-swift-uncensored"
                  ]
                )
                [
                  "start"
                  "stop"
                  "restart"
                ]
            );
      }
    ];
  };
}
