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
in
{
  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle.";
  };

  # The host serving the model talks to its own llama-server over loopback.
  config = lib.mkIf cfg.enable {
    programs.pi.llamaBaseUrl = "http://127.0.0.1:${toString port}";
  };
}
