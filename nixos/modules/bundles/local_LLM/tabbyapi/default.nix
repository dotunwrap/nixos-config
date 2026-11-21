{
  config,
  lib,
  pkgs,
  localLLM,
  ...
}:
let
  llm = config.bundles.local_LLM;
  cfg = llm.tabbyapi;

  home = "/home/${llm.user}";
  install = "${home}/.local/share/tabbyapi";

  # TabbyAPI revision nixpkgs packages (0-unstable-2026-11-01). Its `cu12` extra pins the
  # ExLlamaV3 and PyTorch wheels it was tested with, so the venv matches what upstream ran.
  rev = "01f939c0ee10f10b5f5350047462effad01a4274";

  # nixpkgs' exllamav3 is `broken` without cudaSupport, and a CUDA PyTorch build from source takes
  # hours, so the engine comes from upstream's prebuilt wheels in a venv, like Strata's bundle. The
  # FHS env gives those wheels their usual /usr/lib and the driver's libcuda.
  fhs = pkgs.buildFHSEnv {
    name = "tabbyapi-fhs";
    targetPkgs =
      p: with p; [
        python312
        uv
        git
        cacert
        # Triton builds a small CUDA helper with a C compiler the first time the engine runs.
        gcc
        binutils
        openssl
        zlib
        stdenv.cc.cc.lib
        numactl
        curl
        which
        bash
        coreutils
        findutils
        gnugrep
        gnused
        gawk
        util-linux
      ];
    runScript = "bash";
  };

  installScript = pkgs.writeShellScript "tabbyapi-install-inner" ''
    set -eu
    mkdir -p ${install}
    cd ${install}
    [ -d tabbyAPI/.git ] || git clone https://github.com/theroyallab/tabbyAPI tabbyAPI
    git -C tabbyAPI fetch --quiet origin
    git -C tabbyAPI checkout --quiet ${rev}
    [ -x venv/bin/python ] || uv venv --python ${pkgs.python312}/bin/python3 venv
    uv pip install --python venv/bin/python -e "./tabbyAPI[cu12]"
    echo "TabbyAPI ${rev} installed in ${install}"
  '';

  tabbyapiInstall = pkgs.writeShellScriptBin "tabbyapi-install" ''
    exec ${fhs}/bin/tabbyapi-fhs ${installScript}
  '';

  yaml = pkgs.formats.yaml { };

  # config.yml, as TabbyAPI reads it from its working directory.
  tabbyConfig = yaml.generate "tabbyapi-config.yml" {
    network = {
      host = "127.0.0.1";
      port = localLLM.portFor 6;
      # Loopback behind the router: it has no API key either.
      disable_auth = true;
    };
    logging.log_prompt = false;
    model = {
      model_dir = dirOf cfg.modelPath;
      model_name = baseNameOf cfg.modelPath;
      max_seq_len = cfg.contextSize;
      cache_mode = cfg.cacheMode;
      # Layer split: the CPU expert options do not work with tensor parallelism.
      tensor_parallel = false;
      gpu_split_auto = true;
      autosplit_reserve = cfg.reserveMiB;
      # The n-gram table (52 GB) stays on disk and is read per token, as upstream does by default.
      ngram_ram = false;
      embed_stream_from_disk = true;
      # Strata reads pictures on the CPU; this keeps the vision tower in RAM instead of VRAM.
      inherit (cfg) vision;
      vision_offload = cfg.vision;
    }
    // lib.optionalAttrs (cfg.cpuExperts > 0) {
      cpu_moe_split_experts = cfg.cpuExperts;
    }
    // lib.optionalAttrs (cfg.cpuThreads != null) {
      cpu_moe_threads = cfg.cpuThreads;
    }
    // lib.optionalAttrs (cfg.hugePages != null) {
      # EXL3_MOE_ARENA_HUGE only does anything with the pinned arena.
      cpu_moe_pinned_arena = true;
    };
    # TabbyAPI reads only the stop tokens from the model's generation_config.json, and with no
    # fallbacks a request that omits these runs at temperature 1.0 over the whole vocabulary
    # (top_k 0, top_p 1.0): stray low-probability tokens on a 2-bit quant. These are the values
    # the model ships, applied only when the client sends none.
    sampling = lib.mapAttrs (_: value: {
      override = value;
      force = false;
    }) cfg.sampling;
    draft_model = {
      draft_mode = cfg.draftMode;
      # Strata's `--spec 3 --spec-min-p 0.5`: draft up to 3 tokens, stop early once the chance
      # a drafted token is accepted falls below 0.5.
      draft_num_tokens = cfg.draftTokens;
      dynamic_draft = true;
      draft_confidence = cfg.draftConfidence;
    };
  };

  # The huge-page pool for the expert arena (EXL3_MOE_ARENA_HUGE) has to exist before the model
  # loads, and the pages are not available to anything else while it does. So the unit reserves
  # them when it starts and gives them back when it stops, instead of holding them from boot.
  hugeFile = "/proc/sys/vm/nr_hugepages";
  reserveHuge = pkgs.writeShellScript "tabbyapi-reserve-huge-pages" ''
    set -eu
    want=${toString cfg.hugePageCount}
    # Defragment first: 2 MiB pages need contiguous memory, and the page cache is fragmenting it.
    echo 1 > /proc/sys/vm/compact_memory
    echo "$want" > ${hugeFile}
    got=$(cat ${hugeFile})
    if [ "$got" -lt "$want" ]; then
      echo "tabbyapi: reserved $got of $want huge pages (2 MiB each): memory is too busy or fragmented" >&2
      echo 0 > ${hugeFile}
      exit 1
    fi
  '';
  releaseHuge = pkgs.writeShellScript "tabbyapi-release-huge-pages" ''
    echo 0 > ${hugeFile}
  '';

  start = pkgs.writeShellScript "tabbyapi-start" ''
    set -eu
    [ -x ${install}/venv/bin/python ] || { echo "tabbyapi: not installed: run tabbyapi-install" >&2; exit 1; }
    [ -f ${cfg.modelPath}/config.json ] || { echo "tabbyapi: ${cfg.modelPath} has no model" >&2; exit 1; }
    cd ${install}/tabbyAPI
    install -m 644 ${tabbyConfig} config.yml
    exec ${install}/venv/bin/python main.py
  '';
in
{
  options.bundles.local_LLM.tabbyapi = {
    enable = lib.mkEnableOption ''
      TabbyAPI serving an ExLlamaV3 (EXL3) Qwen3.8-Flash-Next quant, listed by the router as
      `FN-125b-a6b-exl3-2.68bpw`. Install it first with `tabbyapi-install`
    '';

    modelPath = lib.mkOption {
      type = lib.types.str;
      default = "${home}/models/qwen3.8-FN-125b-a6b-exl3-2.68bpw";
      description = "Folder of the EXL3 model (config.json and the safetensors shards).";
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 98304;
      description = "Maximum context (max_seq_len).";
    };

    cacheMode = lib.mkOption {
      type = lib.types.str;
      default = "8,8";
      description = "K,V cache bits (2 to 8 each).";
    };

    cpuExperts = lib.mkOption {
      type = lib.types.int;
      default = 288;
      description = ''
        Routed experts per MoE layer (of 512) kept in system RAM and run on the CPU
        (cpu_moe_split_experts). The 2.68 bpw quant has 40 GB of experts: the two cards
        hold roughly 18 GB of them and the rest goes to RAM, so this is the knob to turn if
        loading runs out of VRAM (raise it) or RAM (lower it). 0 keeps every expert on the GPUs.
      '';
    };

    cpuThreads = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      description = "CPU threads for the offloaded experts; null means half the cores.";
    };

    reserveMiB = lib.mkOption {
      type = lib.types.listOf lib.types.int;
      default = [
        300
        300
      ];
      description = "VRAM to leave free on each card while loading (autosplit_reserve, MiB).";
    };

    draftMode = lib.mkOption {
      type = lib.types.enum [
        "model"
        "disabled"
        "mtp"
        "ngram"
      ];
      default = "mtp";
      description = "Speculative decoding: the model's own MTP head by default.";
    };

    draftTokens = lib.mkOption {
      type = lib.types.int;
      default = 3;
      description = "Tokens drafted per step (draft_num_tokens).";
    };

    draftConfidence = lib.mkOption {
      type = lib.types.float;
      default = 0.5;
      description = "Target acceptance chance for drafted tokens (draft_confidence), 0 to 1.";
    };

    hugePages = lib.mkOption {
      type = lib.types.nullOr (lib.types.enum [ "2m" ]);
      default = null;
      description = ''
        Back the CPU expert arena with huge pages (EXL3_MOE_ARENA_HUGE) and turn on the pinned
        arena (cpu_moe_pinned_arena, which EXL3_MOE_ARENA_HUGE needs). The unit reserves
        `hugePageCount` pages when it starts and releases them when it stops. The pinned arena
        cannot be swapped or reclaimed, so this uses RAM the rest of the system can no longer
        have while the model is loaded. Only 2 MiB pages: 1 GiB pages have to be reserved at boot.
      '';
    };

    hugePageCount = lib.mkOption {
      type = lib.types.ints.positive;
      default = 12288;
      description = ''
        2 MiB huge pages to reserve for the arena (12288 is 24 GiB). It must cover every expert
        kept on the CPU, or the load fails: the 2.68 bpw quant at the default `cpuExperts` needs
        about 23 GiB, and the model's MTP head a little more.
      '';
    };

    sampling = lib.mkOption {
      type = lib.types.attrsOf (lib.types.either lib.types.int lib.types.float);
      default = {
        temperature = 1.0;
        top_k = 20;
        top_p = 0.95;
      };
      description = ''
        Sampler values used when a request sets none (a client's own values win). The defaults are
        the ones in the model's generation_config.json, which TabbyAPI does not read.
      '';
    };

    vision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Let the model read images: loads the quant's vision tower, kept in system RAM.";
    };
  };

  config = lib.mkIf (llm.enable && cfg.enable) {
    environment.systemPackages = [ tabbyapiInstall ];

    bundles.local_LLM.units.tabbyapi = {
      routerName = "FN-125b-a6b-exl3-2.68bpw";
      portOffset = 6;
      useModelName = baseNameOf cfg.modelPath;
      inherit (cfg) contextSize vision;
    };

    systemd.services.tabbyapi = {
      description = "TabbyAPI server (Qwen3.8-Flash-Next EXL3)";
      environment = {
        HOME = home;
      }
      // lib.optionalAttrs (cfg.hugePages != null) {
        EXL3_MOE_PINNED_ARENA = "1";
        EXL3_MOE_ARENA_HUGE = cfg.hugePages;
      };
      serviceConfig = {
        User = llm.user;
        # A "+" prefix runs the step as root: the huge-page pool is a system setting.
        ExecStartPre = [
          "${localLLM.waitGpuFree}"
        ]
        ++ lib.optional (cfg.hugePages != null) "+${reserveHuge}";
        ExecStopPost = lib.optional (cfg.hugePages != null) "+${releaseHuge}";
        ExecStart = "${fhs}/bin/tabbyapi-fhs ${start}";
        # The port opens only after the model has loaded, and the n-gram table is read from disk.
        TimeoutStartSec = "30min";
        TimeoutStopSec = "60s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };
  };
}
