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
    programs.wezterm.extraConfig = ''
      local wezterm = require("wezterm")

      local config = wezterm.config_builder()

      config.font_size = 14.0

      config.hide_tab_bar_if_only_one_tab = true

      config.window_padding = {
      	left = 0,
      	right = 0,
      	top = 0,
      	bottom = 1,
      }

      config.window_decorations = "RESIZE"

      config.keys = {
      	{
      		key = "Enter",
      		mods = "ALT",
      		action = wezterm.action.DisableDefaultAssignment,
      	},
      }

      return config
    '';
  };
}
