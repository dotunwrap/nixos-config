{ monolisa, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  inherit (pkgs.stdenv.hostPlatform) system;
  anyThemeEnabled = any (theme: theme.enable) (attrValues config.themes);
in
{
  options.themes = {
    catppuccin.enable = mkEnableOption "Enable the Catppuccin theme.";
    dracula.enable = mkEnableOption "Enable the Dracula theme.";
    everforest.enable = mkEnableOption "Enable the Everforest theme.";
    gruvbox.enable = mkEnableOption "Enable the Gruvbox theme.";
    mocha.enable = mkEnableOption "Enable the Mocha theme.";
    monokai.enable = mkEnableOption "Enable the Monokai theme.";
    nord.enable = mkEnableOption "Enable the Nord theme.";
  };

  config = mkIf anyThemeEnabled {
    stylix = {
      enable = true;
      polarity = mkDefault "dark";
      fonts.monospace = {
        package = mkDefault monolisa.packages.${system}.default;
        name = "MonoLisa Variable";
      };
      opacity = {
        terminal = mkDefault 0.8;
        applications = mkDefault 0.8;
      };
      cursor = {
        size = mkDefault 32;
        package = mkDefault pkgs.volantes-cursors;
        name = mkDefault "volantes_cursors";
      };
      targets.feh.enable = mkIf config.bundles.dwm.enable true;
    };
  };

  # home.file.".background-image".source = lib.mkIf config.bundles.dwm.enable config.themes.image;
  # xresources.properties =
  #   with config.lib.stylix.colors.withHashtag;
  #   lib.mkIf config.bundles.dwm.enable {
  #     "dwm.normbordercolor" = base00;
  #     "dwm.normbgcolor" = base00;
  #     "dwm.normfgcolor" = base0D;
  #     "dwm.selbordercolor" = base03;
  #     "dwm.selbgcolor" = base0D;
  #     "dwm.selfgcolor" = base00;
  #   };
  # xdg.configFile."lxsession/LXDE/autostart".text = lib.mkIf config.bundles.dwm.enable ''
  #   @xsetroot -cursor_name left_ptr
  # '';
}
