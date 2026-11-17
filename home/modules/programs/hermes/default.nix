{ hermes-agent, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.hermes;
in
{
  # Upstream's Home Manager module provides programs/services.hermes-agent; this
  # module enables it and points it at the local server.
  imports = [ hermes-agent.homeManagerModules.default ];

  options.programs.hermes = {
    llamaBaseUrl = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "http://dosei:8080";
      description = ''
        Base URL of a llama-server router (e.g. one reached over Tailscale), used as
        Hermes' custom OpenAI-compatible endpoint. Null leaves the model unconfigured.
      '';
    };

    defaultModel = lib.mkOption {
      type = lib.types.str;
      # Same one Pi defaults to. The llama-server router loads it on demand.
      default = "unsloth/Qwen3.8-27B-GGUF:Q4_K_XL";
      example = "qwen3.8-27b";
      description = "Model name Hermes sends. It must match what the server calls its model.";
    };

    models = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      example = [
        "qwen3.8-27b"
        "swift-1.5"
      ];
      description = ''
        Models /model offers for the endpoint, besides defaultModel. Hermes only lists what a bare
        `custom` model block names, so a server with several models (the llama-swap router) needs
        them here.
      '';
    };

    contextLength = lib.mkOption {
      type = lib.types.nullOr lib.types.int;
      default = null;
      example = 150000;
      description = ''
        Context window of the endpoint's models. Hermes reads it from the server's /v1/models when
        that reports one (vLLM's `max_model_len`); a router in front, like llama-swap, doesn't pass
        it on, and Hermes then assumes 128K. Null leaves detection to Hermes.
      '';
    };

    supportsVision = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether the server loads a vision projector. Turn off for a language-model-only server.";
    };
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

      # NixOS has no python3 on PATH, and Hermes' own `hermes pm install` binaries
      # (chromium included) are generic-Linux builds that can't run here. Provide both
      # from nixpkgs; the browser tool is pointed at this chromium below.
      extraPackages = [ pkgs.python3 ];

      settings =
        lib.optionalAttrs (cfg.llamaBaseUrl != null) {
          model = {
            provider = "custom";
            base_url = "${cfg.llamaBaseUrl}/v1";
            default = cfg.defaultModel;
            # Hermes can't tell a custom endpoint's model has vision, so with this on, a server
            # that loads the mmproj (see local_LLM) skips the vision_analyze detour through an aux
            # call with a 120s timeout, which a high-reasoning model can exceed.
            supports_vision = cfg.supportsVision;
          };
        }
        // lib.optionalAttrs (cfg.llamaBaseUrl != null) {
          # A named provider gives /model a list to pick from; the `model` block above stays the
          # default selection and Hermes matches it to this entry by endpoint.
          providers.local = {
            name = "local";
            api = "${cfg.llamaBaseUrl}/v1";
            default_model = cfg.defaultModel;
            models = lib.unique ([ cfg.defaultModel ] ++ cfg.models);
          }
          // lib.optionalAttrs (cfg.contextLength != null) {
            context_length = cfg.contextLength;
          };
        }
        // {
          browser.executable_path = lib.getExe pkgs.chromium;

          # Replay only the newest user image from state.db. The default (3) lets 3 to 5 replay,
          # which with live tool images can pass the vLLM per-prompt image limit (HTTP 400).
          vision.replay_recent_images = 1;

          # Open the TUI by default (a bare `hermes`; `--cli` still forces the classic one).
          display = {
            interface = "tui";
            tui_statusbar = "top";
            platforms.cli.show_reasoning = true;
          };

          # FreeCAD MCP server. Needs the FreeCADMCP addon's RPC server running in FreeCAD.
          # Absolute uvx path: Hermes' own staged uv can't run on NixOS. Text-only feedback
          # keeps a screenshot off every tool result, since the local server takes a limited number of images
          # per request; the agent can still ask for one with get_view.
          mcp_servers.freecad = {
            command = lib.getExe' pkgs.uv "uvx";
            args = [
              "freecad-mcp"
              "--only-text-feedback"
            ];
          };

          # Session system-prompt overlay sent with every request: explains this Nix
          # config to the model. Ignored while a display.personality is selected.
          agent = {
            system_prompt = builtins.readFile ./nix-context.md;
            # Default reasoning effort; `/reasoning` still changes it per session.
            reasoning_effort = "medium";
          };
        };
    };
  };
}
