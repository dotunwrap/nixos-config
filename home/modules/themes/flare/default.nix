_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.themes.flare;
  # TODO: Actually find a wallpaper for this?
  outputImage = ./../../../../assets/wallpapers/gruvbox_dark.png;
in
{
  config = lib.mkIf cfg.enable {
    stylix = {
      image = outputImage;
      base16Scheme = ./flare.yaml;
    };

    home.file.".background-image".source = lib.mkIf config.bundles.dwm.enable outputImage;
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
