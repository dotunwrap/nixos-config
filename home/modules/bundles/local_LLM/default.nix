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
in
{
  options.bundles.local_LLM.enable = lib.mkEnableOption "The local LLM bundle.";

  # The host serving the models talks to its own router over loopback. HyperQwen serves with
  # vision (the host's bundles.local_LLM.hyperqwen.vision must be on).
  config = lib.mkIf cfg.enable {
    programs.pi.llamaSwapUrl = "http://127.0.0.1:${toString routerPort}/v1";
  };
}
