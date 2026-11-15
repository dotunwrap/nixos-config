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

  start = pkgs.writeShellScript "hyperqwen-start" ''
    set -eu
    mkdir -p "$TMPDIR"
    export CC=gcc CXX=g++
    cd ${lib.escapeShellArg cfg.repoPath}
    exec bash single-user/start_qwen.sh
  '';
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
        Checkout of syv-ai/HyperQwen with its venv and `models/` already set up. The venv, the
        requantized model and the vLLM patches are installed by hand and are not managed by Nix.
        The venv is not rebuilt here, so a nixpkgs bump that changes the FHS env's gcc or glibc
        can break it. Reinstall the venv if that happens.
      '';
    };

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
    systemd.services.hyperqwen = {
      description = "HyperQwen vLLM server";
      wantedBy = lib.optional cfg.autostart "multi-user.target";
      after = [
        "network.target"
        "llama-cpp.service"
      ];
      conflicts = [ "llama-cpp.service" ];

      environment = {
        HOME = "/home/${cfg.user}";
        TMPDIR = "/var/tmp/hyperqwen";
        HOST = cfg.host;
        PORT = toString cfg.port;
        SPEC = cfg.speculation;
        CTX = cfg.contextMode;
        MAX_LEN = toString cfg.contextSize;
        GPU_UTIL = cfg.gpuMemoryUtilization;
        MAX_SEQS = toString cfg.maxSeqs;
        PREFIX_CACHE = "1";
        # Numbers CUDA devices by PCI bus so device order matches nvidia-smi on mixed cards.
        CUDA_DEVICE_ORDER = "PCI_BUS_ID";
        # Without peer-to-peer, the LL protocol recovered part of tensor parallelism's loss.
        NCCL_PROTO = "LL";
        EXTRA_ARGS = "--tensor-parallel-size ${toString cfg.tensorParallelSize}";
      }
      // lib.optionalAttrs (cfg.contextMode == "long" && cfg.speculation == "mtp") { PTH_FA = "1"; }
      // lib.optionalAttrs (cfg.contextMode == "long" && cfg.speculation == "dflash2") {
        FA2_FP8KV = "0";
      }
      // cfg.extraEnvironment;

      serviceConfig = {
        User = cfg.user;
        ExecStart = "${fhs}/bin/hyperqwen-fhs ${start}";
        # First start compiles kernels and captures CUDA graphs; a cold cache takes minutes.
        TimeoutStartSec = "20min";
        TimeoutStopSec = "60s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };

    # llama-cpp and hyperqwen both claim the GPUs, so only one may start at boot.
    systemd.services.llama-cpp.wantedBy = lib.mkIf (cfg.autostart && config.services.llama-cpp.enable) (
      lib.mkForce [ ]
    );

    # Passwordless control of just this service, mirroring llama-cpp, so benchmarking can
    # restart it without a terminal. Deliberately excludes nixos-rebuild.
    security.sudo.extraRules = [
      {
        users = [ cfg.user ];
        commands =
          map
            (action: {
              command = "/run/current-system/sw/bin/systemctl ${action} hyperqwen.service";
              options = [ "NOPASSWD" ];
            })
            [
              "start"
              "stop"
              "restart"
            ];
      }
    ];
  };
}
