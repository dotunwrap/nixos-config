{
  config,
  lib,
  pkgs,
  localLLM,
  ...
}:
let
  llm = config.bundles.local_LLM;
  cfg = llm.hyperqwen;

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

  # One unit per model. The shared layer (bundles/local_LLM) adds their conflicts, boot wiring,
  # router entries and polkit/sudo rules from the registry below.
  mkService =
    {
      model,
      description,
      port,
    }:
    {
      inherit description;

      environment = {
        HOME = "/home/${llm.user}";
        TMPDIR = "/var/tmp/hyperqwen";
        HOST = llm.host;
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
        User = llm.user;
        ExecStartPre = "${localLLM.waitGpuFree}";
        ExecStart = "${fhs}/bin/hyperqwen-fhs ${start}";
        # First start compiles kernels and captures CUDA graphs; a cold cache takes minutes.
        TimeoutStartSec = "20min";
        TimeoutStopSec = "60s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };

  # Both launchers serve the API name `qwen3.8-27b`, whatever name the client asked for.
  apiName = "qwen3.8-27b";
in
{
  options.bundles.local_LLM.hyperqwen = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Serve HyperQwen, a patched vLLM server for Qwen3.8-27B (OpenAI-compatible).";
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

    model = lib.mkOption {
      type = lib.types.enum (builtins.attrNames modelDirs);
      default = "qwen";
      description = ''
        Model to serve, always under the API name `qwen3.8-27b`. `qwen` is the W4A16 AutoRound
        quant with the repo's int4 head and drafter. `swift` is Swift 1.5 (UkisAI's
        efficient-reasoning fine-tune of Qwen3.8-27B, under the Swift Open License) with int4
        heads, prepared for HyperQwen by daavidhauser. `swiftUncensored` is Swift with the refusal
        direction ablated. Switching needs the model on disk: `HQ_STEPS=+swift hyperqwen-setup` downloads swift
        (about 18GB) and `HQ_STEPS=+uncensored hyperqwen-setup` downloads swiftUncensored (about
        16GB).
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

  config = lib.mkIf (llm.enable && cfg.enable) {
    environment.systemPackages = [ setup ];

    bundles.local_LLM.units = {
      hyperqwen = {
        routerName = "qwen3.8-27b";
        portOffset = 1;
        useModelName = apiName;
        contextSize = cfg.contextSize;
        vision = cfg.vision;
        autostart = true;
      };
      # Swift 1.5 beside the default model: started by hand (or through the router), replacing
      # hyperqwen.service until that is started again. Both serve the API name `qwen3.8-27b`.
      hyperqwen-swift = {
        routerName = "swift-1.5";
        portOffset = 2;
        useModelName = apiName;
        contextSize = cfg.contextSize;
        vision = cfg.vision;
      };
      # Swift with the refusal direction ablated, behind the router as `swift-uncensored`.
      hyperqwen-swift-uncensored = {
        routerName = "swift-uncensored";
        portOffset = 3;
        useModelName = apiName;
        contextSize = cfg.contextSize;
        vision = cfg.vision;
      };
    };

    systemd.services = {
      hyperqwen = mkService {
        inherit (cfg) model;
        description = "HyperQwen vLLM server";
        port = localLLM.portFor 1;
      };
      hyperqwen-swift = mkService {
        model = "swift";
        description = "HyperQwen vLLM server (Swift 1.5)";
        port = localLLM.portFor 2;
      };
      hyperqwen-swift-uncensored = mkService {
        model = "swiftUncensored";
        description = "HyperQwen vLLM server (Swift, uncensored)";
        port = localLLM.portFor 3;
      };
    };
  };
}
