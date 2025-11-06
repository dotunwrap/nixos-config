_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.gruvbox-dark;
  wallpaper = ../../../../assets/wallpapers/gruvbox_pixels.png;
in
{
  config = lib.mkIf cfg.enable {
    stylix = {
      image = wallpaper;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark.yaml";
    };
  };
}
