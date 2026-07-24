_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wezterm;
in
{
  config = lib.mkIf cfg.enable {
    programs.wezterm.settings = {
      hide_tab_bar_if_only_one_tab = true;
      window_padding = {
        left = 0;
        right = 0;
        top = 0;
        bottom = 0;
      };
      window_decorations = "NONE";
      integrated_title_buttons = [ ];
      keys = [
        {
          key = "Enter";
          mods = "ALT";
          action = lib.generators.mkLuaInline "wezterm.action.DisableDefaultAssignment";
        }
      ];
    };
  };
}
