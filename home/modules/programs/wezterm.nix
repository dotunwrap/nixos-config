_:
{ pkgs, ... }:

{
  home.packages = with pkgs; [ wezterm ];

  # TODO: further confgure wezterm
  xdg.configFile."wezterm/wezterm.lua".text = ''
    local wezterm = require 'wezterm'

    local config = {}

    if wezterm.config_builder then
      config = wezterm.config_builder()
    end

    config.audible_bell = "Disabled"
    config.visual_bell = {
      fade_in_function = "EaseIn",
      fade_in_duration_ms = 150,
      fade_out_function = "EaseOut",
      fade_out_duration_ms = 150,
    }

    config.enable_scroll_bar = true

    return config
  '';
}
