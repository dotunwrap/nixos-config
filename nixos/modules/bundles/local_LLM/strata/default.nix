{
  config,
  lib,
  pkgs,
  localLLM,
  ...
}:
let
  llm = config.bundles.local_LLM;
  cfg = llm.strata;

  home = "/home/${llm.user}";
  modelName = "qwen3.8-flash-next-iq3_xxs";

  # Strata ships as a prebuilt Python + CUDA bundle that its own installer unpacks under
  # ~/.local/share/strata, so it needs an FHS loader. Nix doesn't build it: install it once with
  # upstream's install.sh.
  fhs = pkgs.buildFHSEnv {
    name = "strata-fhs";
    targetPkgs =
      p: with p; [
        openssl
        zlib
        stdenv.cc.cc.lib
        numactl
        curl
        pciutils
        procps
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

  # Engine arguments exactly as the tuned `strata launch` preset ran them (dflash2 drafter, int8 KV).
  engineArgs = [
    "--pack"
    "${home}/packs/iq3_xxs"
    "--native"
    "${home}/models/ista-iq3xxs/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00001-of-00002.gguf"
    "--ple-gguf"
    "${home}/models/ista-iq3xxs/Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS-00002-of-00002.gguf"
    "--expert-profile"
    "${cfg.terminalPath}/data/expert-profile.bin"
    "--expert-cache"
    "auto"
    "--prefill"
    "auto"
    "--max-context"
    (toString cfg.contextSize)
    "--kv"
    "int8"
    "--mmap-experts"
    "--draft"
    "dflash2"
    "--draft-model"
    "${home}/dflash2/qwen3.8-flash-next-dflash2.q4_0-selq4.pack"
    "--draft-fallback"
    "none"
    "--mtp-draft-vocab"
    "${home}/dflash2/draft_vocab.bin"
    "--spec"
    "6"
    "--draft-conf"
    "0.35"
    "--layer-split"
    "auto"
  ];

  launchConfig = pkgs.writeText "strata-launch.json" (
    builtins.toJSON {
      exe = "component:strata-engine";
      args = engineArgs;
      cwd = cfg.terminalPath;
      tokenizer = "${home}/packs/iq3_xxs/tokenizer";
      model_name = modelName;
      log = "${home}/.local/state/strata/launch/local-llm.engine.log";
      lib_dirs = [ ];
      gpu = [
        1
        0
      ];
      gpus_asked = true;
      layer_split = "auto";
      gpu_order = "as_given";
      gpu_roles = {
        "0" = "main";
        "1" = "helper";
      };
      host = "127.0.0.1";
      open_browser = false;
    }
  );

  start = pkgs.writeShellScript "strata-start" ''
    set -eu
    cd ${lib.escapeShellArg cfg.terminalPath}
    exec python/bin/python3.12 -m serve.server --engine strata \
      --config ${launchConfig} --host ${llm.host} --port ${toString (localLLM.portFor 4)} \
      --ready-file "$RUNTIME_DIRECTORY/ready.json" --shutdown-timeout 30.0
  '';
in
{
  options.bundles.local_LLM.strata = {
    enable = lib.mkEnableOption ''
      Strata serving Qwen3.8-Flash-Next (IQ3_XXS, dflash2 drafter), with or without the other
      backends. The router lists it as `strata-flash`. Install Strata first with upstream's
      install.sh
    '';

    terminalPath = lib.mkOption {
      type = lib.types.str;
      default = "/home/nia/.local/share/strata/terminal/current";
      description = "Strata Terminal install (what install.sh unpacks) that the unit runs from.";
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 65536;
      description = "Maximum context for the Strata engine (--max-context).";
    };
  };

  config = lib.mkIf (llm.enable && cfg.enable) {
    bundles.local_LLM.units.strata = {
      routerName = "strata-flash";
      portOffset = 4;
      useModelName = modelName;
    };

    systemd.services.strata = {
      description = "Strata server (Qwen3.8-Flash-Next IQ3_XXS)";
      environment.HOME = home;
      serviceConfig = {
        User = llm.user;
        RuntimeDirectory = "strata";
        ExecStartPre = "${localLLM.waitGpuFree}";
        ExecStart = "${fhs}/bin/strata-fhs ${start}";
        # The engine took ~16 minutes to become ready on the first start.
        TimeoutStartSec = "30min";
        TimeoutStopSec = "60s";
        Restart = "on-failure";
        RestartSec = "60s";
      };
    };
  };
}
