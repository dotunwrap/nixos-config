{ hermes-agent, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.hermes;

  # Model Hermes starts with; same one Pi defaults to. The llama-server router loads
  # it on demand.
  defaultModel = "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL";
in
{
  # Upstream's Home Manager module provides programs/services.hermes-agent; this
  # module is a thin wrapper that enables it and points it at the local server.
  imports = [ hermes-agent.homeManagerModules.default ];

  options.programs.hermes.llamaBaseUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "http://dosei:8080";
    description = ''
      Base URL of a llama-server router (e.g. one reached over Tailscale), used as
      Hermes' custom OpenAI-compatible endpoint. Null leaves the model unconfigured.
    '';
  };

  config = lib.mkIf cfg.enable {
    programs.hermes-agent.enable = true;

    # Settings are deep-merged into ~/.hermes/config.yaml on activation, so keys set
    # at runtime (`hermes config set`, /model) are kept. No gateway or backend is started.
    services.hermes-agent = {
      enable = true;
      settings.model = lib.mkIf (cfg.llamaBaseUrl != null) {
        provider = "custom";
        base_url = "${cfg.llamaBaseUrl}/v1";
        default = defaultModel;
      };
    };
  };
}
