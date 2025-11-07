{ monolisa, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.themes = {
    enable = mkEnableOption "Enable stylix themeing";
    image = mkOption { };
    gruvbox-dark.enable = mkEnableOption "Enable gruvbox-dark";
    flare.enable = mkEnableOption "Enable flare";
  };

  config = mkIf config.themes.enable {
    stylix = {
      enable = true;
      image = config.themes.image;
      polarity = "dark";
      fonts = {
        # serif = { };
        # sansSerif = { };
        monospace = {
          package = mkDefault monolisa.packages.x86_64-linux.default;
          name = mkDefault "MonoLisa Variable";
        };
        # emoji = { };
      };
    };

    home.file.".background-image".source = lib.mkIf config.bundles.dwm.enable config.themes.image;
    xresources.properties =
      with config.lib.stylix.colors.withHashtag;
      lib.mkIf config.bundles.dwm.enable {
        "dwm.normbordercolor" = base00;
        "dwm.normbgcolor" = base00;
        "dwm.normfgcolor" = base0D;
        "dwm.selbordercolor" = base03;
        "dwm.selbgcolor" = base0D;
        "dwm.selfgcolor" = base00;
      };
  };
}
