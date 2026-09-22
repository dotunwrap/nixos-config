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
        name = mkDefault "MonoLisa Variable";
      };
      cursor = {
        size = mkDefault 32;
        package = mkDefault pkgs.volantes-cursors;
        name = mkDefault "volantes_cursors";
      };
      targets = {
        feh.enable = mkIf config.bundles.dwm.enable true;
        # x11 and sxiv targets default to enabled regardless of session type and both
        # write to ~/.Xresources; only wire x11 up on X11 (dwm) hosts, and sxiv not at
        # all since we don't use it, so Wayland/Niri hosts don't get a ~/.Xresources
        x11.enable = mkDefault config.bundles.dwm.enable;
        sxiv.enable = mkDefault false;
        # NOTE: gtksourceview target causes inkscape to rebuild every hm generation build
        gtksourceview.enable = mkDefault false;
      };
    };
  };
}
