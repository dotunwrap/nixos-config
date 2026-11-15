_:
{
  config,
  lib,
  osConfig ? null,
  ...
}:
let
  cfg = config.bundles.local_LLM;
  osCfg = osConfig.bundles.local_LLM or null;
  port = if osCfg != null then osCfg.port else 8080;
  # Home Manager is standalone here, so osConfig is usually null and the defaults apply.
  hyperqwenPort = osConfig.bundles.hyperqwen.port or 18020;
in
{
  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle.";

    backend = lib.mkOption {
      type = lib.types.enum [
        "hyperqwen"
        "llama-cpp"
      ];
      default = "hyperqwen";
      description = ''
        Server this host talks to over loopback. It must match whichever of the host's NixOS
        bundles starts at boot (they conflict over the GPUs). HyperQwen serves the model as
        `qwen3.8-27b` with vision (the host's bundles.hyperqwen.vision must be on); llama-cpp is
        the router with its own vision projector.
      '';
    };
  };

  # The host serving the model talks to its own server over loopback.
  config = lib.mkIf cfg.enable {
    programs = {
      # Pi keeps using llama-server's router API, which HyperQwen does not provide.
      pi.llamaBaseUrl = "http://127.0.0.1:${toString port}";
      hermes =
        if cfg.backend == "hyperqwen" then
          {
            llamaBaseUrl = "http://127.0.0.1:${toString hyperqwenPort}";
            defaultModel = "qwen3.8-27b";
            models = [ "swift-1.5" ];
            supportsVision = true;
          }
        else
          {
            llamaBaseUrl = "http://127.0.0.1:${toString port}";
            defaultModel = "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL";
            supportsVision = true;
          };
    };
  };
}
