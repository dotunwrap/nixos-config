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

  # Strata ships as a prebuilt Python + CUDA bundle, so it needs an FHS loader. Nix doesn't build
  # it: it fetches upstream's release tarballs (the same files `strata update` downloads, checked
  # against the release's SHA256SUMS.txt) and unpacks them into the store. Bump `release`, the
  # versions and the hashes together; the feed's engine and Control versions move separately.
  release = "v0.2.16";
  controlVersion = "0.1.62";
  engineVersion = "0.1.62";
  engineFolder = "${engineVersion}-linux-x86_64-cuda-cuda13";

  fetchRelease =
    name: sha256:
    pkgs.fetchurl {
      url = "https://github.com/Niko1221/Strata/releases/download/${release}/${name}";
      inherit name sha256;
    };

  controlSrc = fetchRelease "strata-control-${controlVersion}-linux-x86_64.tar.gz" "045b6a7d7fbfbddab814794db5763d6244c887a394403b9fe0e8a4714d9bef8c";
  engineSrc = fetchRelease "strata-engine-${engineVersion}-linux-x86_64-cuda-cuda13.tar.gz" "6723e1b6b6042bfe1d368723ebf873afb0fa65f4f1908d948dd865098f6cfb9e";

  # The component folder (STRATA_COMPONENTS_DIR) as `strata update` would have left it. Control is
  # unpacked inside it rather than linked in: Strata refuses an active.json whose folder resolves
  # outside the control folder.
  components = pkgs.runCommand "strata-components-${controlVersion}" { } ''
    mkdir -p $out/control/${controlVersion} $out/engine/${engineFolder}
    tar -xzf ${controlSrc} -C $out/control/${controlVersion}
    tar -xzf ${engineSrc} -C $out/engine/${engineFolder}
    echo '${
      builtins.toJSON {
        version = controlVersion;
        folder = controlVersion;
        sha256 = "045b6a7d7fbfbddab814794db5763d6244c887a394403b9fe0e8a4714d9bef8c";
      }
    }' > $out/control/active.json
  '';
  control = "${components}/control/${controlVersion}";
  engine = "${components}/engine/${engineFolder}";

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

  # The PLE (n-gram) table the Gyro noPLE files lack. Any of Delgon's tables fits any Gyro file.
  pleTable = "${home}/models/qwen3.8-flash-next-ple/Qwen3.8-Flash-Next-PLE-IQ4_NL.gguf";

  # Setup's Gyro config: the MTP draft head with Strata's IQ3_XXS settings.
  gyroDraft = [
    "--mtp"
    "/home/nia/mtp/rt"
    "--spec"
    "4"
    "--spec-min-p"
    "0.5"
  ];

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
      pleShard = true;
      mmproj = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
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
      pleShard = true;
      mmproj = "mmproj-Qwen3.8-Flash-Next-BF16.gguf";
      pack = "${home}/packs/coder_iq1_m";
      profile = "expert-profile-coder.bin";
      # The experts the GPU cache does not hold are read through the OS page cache, which uses
      # about 11 GB less RAM than --resident-experts (the Strata monitor's RAM tier stays empty).
      # Cold prompts read slower until the cache warms: 629-1,018 tok/s against 2,200+ resident
      # on a 5K-token first request, and about 18% slower at 16K; within 3% at 95K.
      kv = "int8";
      experts = "--mmap-experts";
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
        "3"
        "--spec-min-p"
        "0.5"
      ];
    };

    strata-swift = {
      description = "Strata server (Swift 1.5 Qwen3.8-Flash-Next IQ3_XXS)";
      routerName = "strata-swift";
      portOffset = 7;
      modelName = "swift-1.5-qwen3.8-flash-next-iq3_xxs";
      models = "${home}/models/swift-1.5-iq3xxs";
      files = "Swift-Qwen3.8-Flash-Next-GSQ-RCO-IQ3_XXS";
      # Swift's shards are a plain size split (layers 0-12 plus the PLE table in shard 1, layers
      # 13-47 in shard 2), so there is no separate PLE file: the engine finds the table in shard 1
      # and `--ple-gguf` is left out. Built with tools/iq_pack.py (see ~/packs/swift_iq3_xxs/build.log).
      pleShard = false;
      # Swift's own mmproj is not downloaded; the base model's picture reader is shared.
      mmproj = "../ista-iq3xxs/mmproj-Qwen3.8-Flash-Next-BF16.gguf";
      pack = "${home}/packs/swift_iq3_xxs";
      # Swift is a fine-tune of the same model, so the base IQ3_XXS expert profile is reused.
      profile = "expert-profile.bin";
      kv = "int8";
      experts = "--mmap-experts";
      extra = [ ];
      # What `strata launch --family swift` picks: the MTP draft layer, with the same settings as
      # the setup-written IQ3_XXS config.
      draft = [
        "--mtp"
        "/home/nia/mtp/rt"
        "--spec"
        "4"
        "--spec-min-p"
        "0.5"
      ];
    };

    # agentionai's Gyro quants (trellis experts, Hadamard-rotated) are one noPLE file each: the
    # n-gram table is the separate PLE GGUF, passed with --ple-gguf. Strata's GYRO.md serves them as
    # --pack plus --native <file>, with the MTP head and the IQ3_XXS expert profile.
    strata-gyro-m = {
      description = "Strata server (Gyro-M TQ2_0 Qwen3.8-Flash-Next)";
      routerName = "strata-gyro-m";
      portOffset = 8;
      modelName = "gyro-m-qwen3.8-flash-next-tq2_0";
      models = "${home}/models/gyro-m";
      native = "${home}/models/gyro-m/Qwen3.8-Flash-Next-Gyro-M-TQ2_0-noPLE.gguf";
      pleGguf = pleTable;
      mmproj = "../ista-iq3xxs/mmproj-Qwen3.8-Flash-Next-BF16.gguf";
      # Built once with: tools/iq_pack.py --gguf <native> --out ~/packs/gyro_m --compat-bf16
      pack = "${home}/packs/gyro_m";
      profile = "expert-profile.bin";
      # 29.9 GiB of experts do not all fit next to the KV cache; --expert-cache auto streams the
      # rest. Strata's GYRO.md serves the trellis packs without --mmap-experts.
      kv = "int8";
      experts = [ ];
      extra = [ ];
      draft = gyroDraft;
    };

    strata-gyro-coder = {
      description = "Strata server (Gyro-Coder-L TQ3_0 Qwen3.8-Flash-Next)";
      routerName = "strata-gyro-coder";
      portOffset = 9;
      modelName = "gyro-coder-l-qwen3.8-flash-next-tq3_0";
      models = "${home}/models/gyro-coder-l";
      native = "${home}/models/gyro-coder-l/Qwen3.8-Flash-Next-Gyro-Coder-L-TQ3_0-noPLE.gguf";
      pleGguf = pleTable;
      mmproj = "../ista-iq3xxs/mmproj-Qwen3.8-Flash-Next-BF16.gguf";
      pack = "${home}/packs/gyro_coder_l";
      profile = "expert-profile-coder.bin";
      kv = "int8";
      experts = [ ];
      extra = [ ];
      draft = gyroDraft;
    };
  };

  mkVariant =
    unit: v:
    let
      # The two-shard IQ sets name `files`; the Gyro quants give the single file as `native`.
      native = v.native or "${v.models}/${v.files}-00001-of-00002.gguf";
      ple = v.pleGguf or (if v.pleShard then "${v.models}/${v.files}-00002-of-00002.gguf" else null);

      # Engine arguments as the tuned `strata launch` preset ran them (int8 KV).
      engineArgs = [
        "--pack"
        v.pack
        "--native"
        native
      ]
      # With a two-shard --native the engine needs the real second shard beside shard 1 (it checks
      # the shard's split.count/split.no metadata), so a standalone PLE file such as Delgon's
      # Qwen3.8-Flash-Next-PLE-GGUF cannot stand in for it. A single noPLE file takes the table
      # as its own file.
      ++ lib.optionals (ple != null) [
        "--ple-gguf"
        ple
      ]
      ++ [
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
      ]
      ++ lib.toList v.experts
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
        mmproj = "${v.models}/${v.mmproj}";
        model = native;
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
          # Add the picture reader's program, from the engine component.
          config="$RUNTIME_DIRECTORY/launch.json"
          ${lib.getExe pkgs.jq} --arg exe ${engine}/strata-vision '.vision.exe = $exe' ${launchConfig} > "$config"
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
        environment = {
          HOME = home;
          STRATA_COMPONENTS_DIR = "${components}";
        };
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
    unit: _:
    {
      strata = cfg.enable;
      strata-coder = cfg.coder.enable;
      strata-swift = cfg.swift.enable;
      strata-gyro-m = cfg.gyroM.enable;
      strata-gyro-coder = cfg.gyroCoder.enable;
    }
    .${unit}
  ) variants;
  built = lib.mapAttrs mkVariant enabled;
in
{
  options.bundles.local_LLM.strata = {
    enable = lib.mkEnableOption ''
      Strata serving Qwen3.8-Flash-Next (IQ3_XXS, dflash2 drafter), with or without the other
      backends. The router lists it as `strata-flash`. Strata itself comes from Nix (see
      the release pinned at the top of this file)
    '';

    terminalPath = lib.mkOption {
      type = lib.types.str;
      default = "${control}";
      description = "Strata Control (the Terminal) that the unit runs from: the release tarball, unpacked into the store.";
    };

    coder.enable = lib.mkEnableOption ''
      ISTA-DASLab's Qwen3.8-Flash-Next Coder (IQ1_M: half the experts, kept for code, tools and
      images) as a second Strata model, listed by the router as `strata-coder`. It has no dflash2
      drafter. Its files and pack go in ~/models/coder-iq1m and ~/packs/coder_iq1_m
    '';

    swift.enable = lib.mkEnableOption ''
      UkisAI's Swift 1.5 (a fine-tune of Qwen3.8-Flash-Next that thinks shorter; IQ3_XXS) as a
      third Strata model, listed by the router as `strata-swift`. Its shards go in
      ~/models/swift-1.5-iq3xxs and its pack, built with Strata's tools/iq_pack.py, in
      ~/packs/swift_iq3_xxs
    '';

    gyroM.enable = lib.mkEnableOption ''
      agentionai's Gyro-M (TQ2_0, about IQ3_XXS quality with 20% less GPU memory) as a Strata
      model, listed by the router as `strata-gyro-m`. Its noPLE file goes in ~/models/gyro-m, the
      PLE table in ~/models/qwen3.8-flash-next-ple, and its pack (tools/iq_pack.py --compat-bf16)
      in ~/packs/gyro_m
    '';

    gyroCoder.enable = lib.mkEnableOption ''
      agentionai's Gyro-Coder-L (TQ3_0, tuned for code) as a Strata model, listed by the router as
      `strata-gyro-coder`. Its noPLE file goes in ~/models/gyro-coder-l and its pack in
      ~/packs/gyro_coder_l. agentionai's card says Coder-L needs their Strata branch, so check the
      pack's `--load-check` (native_expert_parity) before relying on it
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
