_:
{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  cfg = config.bundles.local_LLM;
  # Home Manager is standalone here, so osConfig is usually null and the defaults apply.
  routerPort = osConfig.bundles.local_LLM.port or 18020;
  # The router doesn't relay vLLM's max_model_len, so Hermes and Pi are told the window directly.
  hyperqwenContext = osConfig.bundles.local_LLM.hyperqwen.contextSize or 150000;
  strataContext = osConfig.bundles.local_LLM.strata.contextSize or 262144;
in
{
  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle.";

    router.models = lib.mkOption {
      type = lib.types.attrsOf lib.types.int;
      default = {
        "qwen3.8-27b" = hyperqwenContext;
        "swift-1.5" = hyperqwenContext;
        "swift-uncensored" = hyperqwenContext;
        "strata-flash" = strataContext;
        "strata-coder" = strataContext;
        "strata-swift" = strataContext;
      };
      description = ''
        Models the host's llama-swap router (bundles.local_LLM.router) lists, with their context
        windows. The router starts whichever backend a request names, so Pi gets all of them.
      '';
    };
  };

  # The host serving the models talks to its own router over loopback. HyperQwen serves with
  # vision (the host's bundles.local_LLM.hyperqwen.vision must be on).
  config = lib.mkIf cfg.enable {
    programs = {
      pi.llamaSwapUrl = "http://127.0.0.1:${toString routerPort}/v1";
      hermes = {
        baseUrl = "http://127.0.0.1:${toString routerPort}";
        defaultModel = "swift-1.5";
        models = lib.remove "swift-1.5" (lib.attrNames cfg.router.models);
        contextLength = hyperqwenContext;
        supportsVision = true;
      };
    };
  };
}
