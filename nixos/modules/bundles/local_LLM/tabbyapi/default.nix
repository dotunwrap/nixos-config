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
    }
    // lib.optionalAttrs (cfg.cpuExperts > 0) {
      cpu_moe_split_experts = cfg.cpuExperts;
    }
    // lib.optionalAttrs (cfg.cpuThreads != null) {
      cpu_moe_threads = cfg.cpuThreads;
    };
    draft_model.draft_mode = cfg.draftMode;
  };

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
      `exl3-flash`. Install it first with `tabbyapi-install`
    '';

    modelPath = lib.mkOption {
      type = lib.types.str;
      default = "${home}/models/qwen3.8-flash-next-exl3-2.68bpw";
      description = "Folder of the EXL3 model (config.json and the safetensors shards).";
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 65536;
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
        768
        768
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

    vision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Advertise image input to clients (the quant ships its vision tower).";
    };
  };

  config = lib.mkIf (llm.enable && cfg.enable) {
    environment.systemPackages = [ tabbyapiInstall ];

    bundles.local_LLM.units.tabbyapi = {
      routerName = "exl3-flash";
      portOffset = 6;
      useModelName = baseNameOf cfg.modelPath;
      inherit (cfg) contextSize vision;
    };

    systemd.services.tabbyapi = {
      description = "TabbyAPI server (Qwen3.8-Flash-Next EXL3)";
      environment.HOME = home;
      serviceConfig = {
        User = llm.user;
        ExecStartPre = "${localLLM.waitGpuFree}";
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
