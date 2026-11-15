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
  # module enables it and points it at the local server.
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

    # Settings are deep-merged into ~/.hermes/config.yaml on activation. The install is
    # marked managed, so `hermes config set` is refused: change settings here. Keys
    # removed from this set stay in config.yaml until deleted by hand.
    # optionalAttrs, not mkIf: the upstream module serializes `settings` straight to
    # YAML, so an mkIf wrapper would leak `_type: if` into config.yaml.
    services.hermes-agent = {
      enable = true;
      settings =
        lib.optionalAttrs (cfg.llamaBaseUrl != null) {
          model = {
            provider = "custom";
            base_url = "${cfg.llamaBaseUrl}/v1";
            default = defaultModel;
          };
        }
        // {
          # Session system-prompt overlay sent with every request: explains this Nix
          # config to the model. Ignored while a display.personality is selected.
          agent.system_prompt = builtins.readFile ./nix-context.md;
        };
    };
  };
}
