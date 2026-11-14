_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.bundles.local_LLM;

  # The router drops the "UD-" prefix from Unsloth quants when naming models.
  modelId = builtins.replaceStrings [ ":UD-" ] [ ":" ] cfg.model;

  # User-supplied per-model sections, keyed by router model id. A `UD-` prefix
  # is stripped from the key so either spelling works.
  extraSections = lib.mapAttrs' (
    name: value: lib.nameValuePair (builtins.replaceStrings [ ":UD-" ] [ ":" ] name) value
  ) cfg.modelSettings;

  # Qwen-Sharp-Chat-Templates (froggeric v22.5 base): terse answers, thinking
  # retention for cache hits across turns, and effort steering. Pinned by revision.
  # Per request, `chat_template_kwargs = { terse = false; }` turns the terseness off.
  chatTemplate = pkgs.fetchurl {
    url = "https://huggingface.co/peculiar-ragdoll/Qwen-Sharp-Chat-Templates/resolve/6a78b888557f8c9987f51bca98d02d8f69682044/chat_template.jinja";
    hash = "sha256-zf85+ya2DckPqikucmZVxrIfYttJeEbgLkxLurlCqEo=";
  };

  # Router-mode presets: [*] applies to every model the router serves (including
  # ones pulled into the cache later), the model section adds MTP and sampling
  # for the default Qwen model only, since other models may have no MTP head.
  # Built once per profile (see `headless`); the service picks one at startup.
  mkPresets =
    name: profile:
    pkgs.writeText "llama-presets-${name}.ini" (
      lib.generators.toINIWithGlobalSection { } {
        globalSection.version = 1;
        sections = lib.recursiveUpdate {
          "*" = {
            ctx-size = profile.contextSize;
            n-gpu-layers = 999;
            # Tensor split runs both GPUs in parallel; the default layer split
            # pipelines them and roughly halves decode speed on dual-GPU rigs.
            split-mode = "tensor";
            tensor-split = profile.tensorSplit;
            flash-attn = "on";
            cache-type-k = cfg.cacheType;
            cache-type-v = cfg.cacheType;
            parallel = 1;
            jinja = true;
            dedup-cache-models = true;
          }
          # Without vision, skip the projector and its ~1GB of VRAM. With it, the
          # router downloads and loads the repo's mmproj file automatically.
          // lib.optionalAttrs (!cfg.vision) { no-mmproj = true; }
          // lib.optionalAttrs (cfg.vision && !profile.mmprojOffload) { no-mmproj-offload = true; };

          ${modelId} = {
            hf-repo = cfg.model;
            load-on-startup = true;
            chat-template-file = "${chatTemplate}";
            # MTP speculative decoding using the draft head embedded in the unsloth GGUFs
            spec-type = "draft-mtp";
            spec-draft-n-max = 3;
            # Reuse cached KV for matching prompt chunks (e.g. the large agent system prompt)
            # when only part of the prefix differs between requests.
            cache-reuse = 256;
            # Pi can only toggle thinking on/off for this template (it shows "medium"),
            # so pin the template's own effort level server-side.
            reasoning-effort = "xhigh";
            # Qwen recommended sampling for thinking mode
            temp = 0.6;
            top-p = 0.95;
            top-k = 20;
          };
        } extraSections;
      }
    );

  profiles = {
    connected = { inherit (cfg) contextSize tensorSplit mmprojOffload; };
    headless = { inherit (cfg.headless) contextSize tensorSplit mmprojOffload; };
  };
  presetFiles = lib.mapAttrs mkPresets profiles;

  # A display counts as connected when any connector on an NVIDIA DRM card
  # reports "connected". If no NVIDIA card is found (driver not loaded yet) we
  # assume connected, the safe choice since it uses less VRAM.
  selectPreset = pkgs.writeShellScript "llama-select-preset" ''
    profile=connected
    found=0
    connected=0
    for card in /sys/class/drm/card[0-9]*; do
      [ -e "$card/device/driver" ] || continue
      [ "$(basename "$(readlink -f "$card/device/driver")")" = nvidia ] || continue
      found=1
      for status in "$card"-*/status; do
        [ -r "$status" ] || continue
        if [ "$(cat "$status")" = connected ]; then
          connected=1
        fi
      done
    done
    if [ "$found" = 1 ] && [ "$connected" = 0 ]; then
      profile=headless
    fi
    echo "llama-cpp: using $profile preset"
    cp ${presetFiles.connected} "$RUNTIME_DIRECTORY/presets-connected.ini"
    cp ${presetFiles.headless} "$RUNTIME_DIRECTORY/presets-headless.ini"
    ln -sf "presets-$profile.ini" "$RUNTIME_DIRECTORY/presets.ini"
  '';
in
{
  options = {
    bundles.local_LLM = {
      enable = lib.mkEnableOption "The local LLM bundle.";

      model = lib.mkOption {
        type = lib.types.str;
        default = "unsloth/Qwen3.8-27B-GGUF:UD-Q4_K_XL";
        description = ''
          Default Hugging Face GGUF repo and quant (`repo:quant`), loaded on
          startup and downloaded into `/var/cache/llama-cpp` if missing. Clients use
          `modelId`. With 16GB + 12GB of VRAM, anything up
          to roughly Q6_K still leaves room for the KV cache.
        '';
      };

      modelId = lib.mkOption {
        type = lib.types.str;
        readOnly = true;
        default = modelId;
        description = "Model id clients use, as named by the llama-server router.";
      };

      modelSettings = lib.mkOption {
        type = lib.types.attrsOf (
          lib.types.attrsOf (
            lib.types.oneOf [
              lib.types.bool
              lib.types.int
              lib.types.float
              lib.types.str
            ]
          )
        );
        default = { };
        example = lib.literalExpression ''
          {
            "unsloth/Some-Model-GGUF:Q5_K_M" = {
              ctx-size = 65536;
              temp = 0.7;
            };
          }
        '';
        description = ''
          Per-model preset sections, keyed by router model id. Keys are
          `llama-server` flags without dashes and override the global defaults
          for that model. Setting `hf-repo` makes the router download the model
          if it is missing. The default model's section is merged with these.
        '';
      };

      vision = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = ''
          Load the multimodal projector (mmproj) so models can read images.
          Costs roughly 1GB of VRAM plus an image-encoder buffer.
        '';
      };

      mmprojOffload = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = ''
          Keep the vision projector on the GPU. Disable to run it on the CPU, which
          saves its VRAM (~0.9GB, all on GPU 0) at the cost of slower image encoding.
          Only used when `vision` is enabled.
        '';
      };

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port llama-server listens on.";
      };

      host = lib.mkOption {
        type = lib.types.str;
        default = "127.0.0.1";
        description = ''
          Address llama-server binds to. There is no API key, so anything other than
          loopback relies on the firewall (only trusted interfaces such as Tailscale).
        '';
      };

      contextSize = lib.mkOption {
        type = lib.types.int;
        default = 131072;
        description = "Context window, in tokens.";
      };

      cacheType = lib.mkOption {
        type = lib.types.enum [
          "f16"
          "q8_0"
        ];
        default = "q8_0";
        description = ''
          KV cache type. q8_0 is the floor: q4_0 visibly hurts long-context
          accuracy, so it is deliberately not offered.
        '';
      };

      tensorSplit = lib.mkOption {
        type = lib.types.str;
        default = "16,12";
        description = ''
          Per-GPU split ratio, in CUDA device order. CUDA orders fastest-first,
          so device 0 is the 4070 Ti SUPER (16GB) and device 1 the 4070 SUPER (12GB).
        '';
      };

      headless = {
        contextSize = lib.mkOption {
          type = lib.types.int;
          default = cfg.contextSize;
          defaultText = lib.literalExpression "config.bundles.local_LLM.contextSize";
          description = ''
            Context window used when no display is connected to the NVIDIA GPUs.
            With no desktop to feed, the freed VRAM can go to the KV cache.
          '';
        };

        tensorSplit = lib.mkOption {
          type = lib.types.str;
          default = cfg.tensorSplit;
          defaultText = lib.literalExpression "config.bundles.local_LLM.tensorSplit";
          description = "Per-GPU split ratio used when no display is connected.";
        };

        mmprojOffload = lib.mkOption {
          type = lib.types.bool;
          default = cfg.mmprojOffload;
          defaultText = lib.literalExpression "config.bundles.local_LLM.mmprojOffload";
          description = "Keep the vision projector on the GPU when no display is connected.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # llama.cpp over vLLM/SGLang: tensor parallelism there splits evenly, which
    # would cap this mismatched pair at 2x12GB. llama.cpp splits unevenly and
    # runs GGUF quants that fit in 28GB. Its tensor split plus MTP speculative
    # decoding closes much of the decode-speed gap to vLLM.
    #
    # Runs in router mode (no fixed model): any model in /var/cache/llama-cpp can
    # be loaded by name on request, one at a time, without a rebuild. Pull new
    # ones with `POST /models` and refresh with `GET /models?reload=1`.
    services.llama-cpp = {
      enable = true;
      package = pkgs.llama-cpp.override { cudaSupport = true; };
      settings = {
        inherit (cfg) host port;
        models-preset = "/run/llama-cpp/presets.ini";
        models-max = 1;
      };
    };

    # Pick the preset set for the current display state each time the server starts.
    systemd.services.llama-cpp.serviceConfig = {
      RuntimeDirectory = "llama-cpp";
      ExecStartPre = selectPreset;
    };
  };
}
