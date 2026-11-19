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

  # One Strata server per model file set. Both read the same engine and share the GPUs, so the
  # router runs one at a time like every other unit.
  variants = {
    strata = {
      description = "Strata server (Qwen3.8-Flash-Next IQ3_XXS)";
      routerName = "strata-flash";
      portOffset = 4;
      modelName = "qwen3.8-flash-next-iq3_xxs";
      models = "${home}/models/ista-iq3xxs";
      files = "Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS";
      pack = "${home}/packs/iq3_xxs";
      profile = "expert-profile.bin";
      # 47 GB of experts do not fit in RAM, so they are read through the OS file cache.
      kv = "int8";
      experts = "--mmap-experts";
      extra = [ ];
      # The tuned `strata launch` preset's dflash2 drafter. Strata has none for the Coder.
      draft = [
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
      ];
    };

    strata-coder = {
      description = "Strata server (Qwen3.8-Flash-Next Coder IQ1_M)";
      routerName = "strata-coder";
      portOffset = 5;
      modelName = "qwen3.8-flash-next-coder-iq1_m";
      models = "${home}/models/coder-iq1m";
      files = "Qwen3.8-Flash-Next-GSQ-RCO-IQ1_M";
      pack = "${home}/packs/coder_iq1_m";
      profile = "expert-profile-coder.bin";
      # The 25 GB of experts are held in RAM (what the Strata monitor counts as its RAM tier);
      # the GPU expert cache (--expert-cache auto) still fills the free VRAM first.
      kv = "int8";
      experts = "--resident-experts";
      # Leave 300 MiB per card instead of the default 700, so the GPU expert cache gets the rest
      # (cards at about 95-97% instead of 91-94%).
      # --kv-resident keeps 32768 cells of K/V per layer in VRAM and the rest in pinned RAM, which
      # frees VRAM for expert slots (about 3.6 GB of RAM at 256K context with int8).
      extra = [
        "--vram-reserve-mib"
        "300"
        "--kv-resident"
        "32768"
        # Prompt chunks sized for the layer split, at the b/a ratio calibration measured best:
        # about 18% faster prompt reading on long prompts, decode unchanged.
        "--prefill-pipe"
        "1536"
      ];
      # The Coder's MTP draft layer, fetched once by `strata launch --family coder --model iq1_m
      # --mtp on --model-path ~/models/coder-iq1m` into ~/mtp/rt. A native (IQ) pack needs --spec
      # T (T >= 2). Measured 94 tok/s at 77% acceptance, against about 65 tok/s with prompt lookup.
      draft = [
        "--mtp"
        "/home/nia/mtp/rt"
        "--spec"
        "4"
        # Calibrated (strata engine calibrate): 0.7 drafts less often but accepts 88% instead of 72%,
        # about 7% faster decode than Strata's default 0.5.
        "--spec-min-p"
        "0.7"
      ];
    };
  };

  mkVariant =
    unit: v:
    let
      # Engine arguments as the tuned `strata launch` preset ran them (int8 KV).
      engineArgs = [
        "--pack"
        v.pack
        "--native"
        "${v.models}/${v.files}-00001-of-00002.gguf"
        "--ple-gguf"
        "${v.models}/${v.files}-00002-of-00002.gguf"
        "--expert-profile"
        "${cfg.terminalPath}/data/${v.profile}"
        "--expert-cache"
        "auto"
        "--prefill"
        "auto"
        "--max-context"
        (toString cfg.contextSize)
        "--kv"
        v.kv
        v.experts
      ]
      ++ v.draft
      ++ v.extra
      ++ [
        "--layer-split"
        "auto"
      ]
      ++ lib.optional cfg.vision "--vision";

      # The picture reader (llama.cpp mtmd + the model's mmproj) runs on the CPU: the cards are
      # under 24 GB, where Strata's own rule picks the CPU reader too. Its program ships in the
      # engine component, whose folder name carries the engine version, so the start script adds
      # `exe` at run time.
      visionSection = {
        mmproj = "${v.models}/mmproj-Qwen3.8-Flash-Next-BF16.gguf";
        model = "${v.models}/${v.files}-00001-of-00002.gguf";
        gpu = false;
        max_tokens = 300;
        threads = 8;
      };

      launchConfig = pkgs.writeText "${unit}-launch.json" (
        builtins.toJSON (
          {
            exe = "component:strata-engine";
            args = engineArgs;
            cwd = cfg.terminalPath;
            tokenizer = "${v.pack}/tokenizer";
            model_name = v.modelName;
            log = "${home}/.local/state/strata/launch/${unit}.engine.log";
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
          // lib.optionalAttrs cfg.vision { vision = visionSection; }
        )
      );

      start = pkgs.writeShellScript "${unit}-start" ''
        set -eu
        cd ${lib.escapeShellArg cfg.terminalPath}
        config=${launchConfig}
        ${lib.optionalString cfg.vision ''
          # Add the picture reader's program, from the newest installed engine component.
          reader=$(ls -d ${home}/.local/share/strata/components/engine/*/strata-vision | sort | tail -n 1)
          config="$RUNTIME_DIRECTORY/launch.json"
          ${lib.getExe pkgs.jq} --arg exe "$reader" '.vision.exe = $exe' ${launchConfig} > "$config"
        ''}
        exec python/bin/python3.12 -m serve.server --engine strata \
          --config "$config" --host ${llm.host} --port ${toString (localLLM.portFor v.portOffset)} \
          --ready-file "$RUNTIME_DIRECTORY/ready.json" --shutdown-timeout 30.0
      '';
    in
    {
      unit = {
        inherit (v) routerName portOffset;
        useModelName = v.modelName;
        inherit (cfg) contextSize vision;
      };
      service = {
        inherit (v) description;
        environment.HOME = home;
        serviceConfig = {
          User = llm.user;
          RuntimeDirectory = unit;
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

  enabled = lib.filterAttrs (
    unit: _: if unit == "strata" then cfg.enable else cfg.coder.enable
  ) variants;
  built = lib.mapAttrs mkVariant enabled;
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

    coder.enable = lib.mkEnableOption ''
      ISTA-DASLab's Qwen3.8-Flash-Next Coder (IQ1_M: half the experts, kept for code, tools and
      images) as a second Strata model, listed by the router as `strata-coder`. It has no dflash2
      drafter. Its files and pack go in ~/models/coder-iq1m and ~/packs/coder_iq1_m
    '';

    vision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = ''
        Let the model read images: the mmproj file (mmproj-Qwen3.8-Flash-Next-BF16.gguf, 0.9 GB,
        next to the model files) and a CPU picture reader, about 0.9 GB of RAM.
      '';
    };

    contextSize = lib.mkOption {
      type = lib.types.int;
      default = 262144;
      description = "Maximum context for the Strata engine (--max-context).";
    };
  };

  config = lib.mkIf llm.enable {
    bundles.local_LLM.units = lib.mapAttrs (_: b: b.unit) built;
    systemd.services = lib.mapAttrs (_: b: b.service) built;
  };
}
