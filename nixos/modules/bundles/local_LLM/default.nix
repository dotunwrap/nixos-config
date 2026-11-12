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

  # Router-mode presets: [*] applies to every model the router serves (including
  # ones pulled into the cache later), the model section adds MTP and sampling
  # for the default Qwen model only, since other models may have no MTP head.
  presets = pkgs.writeText "llama-presets.ini" (
    lib.generators.toINIWithGlobalSection { } {
      globalSection.version = 1;
      sections = lib.recursiveUpdate {
        "*" = {
          ctx-size = cfg.contextSize;
          n-gpu-layers = 999;
          # Tensor split runs both GPUs in parallel; the default layer split
          # pipelines them and roughly halves decode speed on dual-GPU rigs.
          split-mode = "tensor";
          tensor-split = cfg.tensorSplit;
          flash-attn = "on";
          cache-type-k = cfg.cacheType;
          cache-type-v = cfg.cacheType;
          # Text-only: skip the vision projector and its ~1GB of VRAM
          no-mmproj = true;
          parallel = 1;
          jinja = true;
          dedup-cache-models = true;
        };

        ${modelId} = {
          hf-repo = cfg.model;
          load-on-startup = true;
          # MTP speculative decoding using the draft head embedded in the unsloth GGUFs
          spec-type = "draft-mtp";
          spec-draft-n-max = 2;
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

      port = lib.mkOption {
        type = lib.types.port;
        default = 8080;
        description = "Port llama-server listens on (localhost only).";
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
        host = "127.0.0.1";
        inherit (cfg) port;
        models-preset = presets;
        models-max = 1;
      };
    };
  };
}
