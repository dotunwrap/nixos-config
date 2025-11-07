_: {
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.themes.gruvbox-dark;
  inputImage = ./../../../../assets/wallpapers/gruvbox_pixels.png;
  brightness = "-15";
  contrast = "0";
  fillColor = "black";
  outputImage = pkgs.runCommand "dimmed-background.png" {} ''
    ${lib.getExe' pkgs.imagemagick "convert"} "${inputImage}" -brightness-contrast ${brightness},${contrast} -fill ${fillColor} $out
  '';
in {
  config = lib.mkIf cfg.enable {
    stylix = {
      image = outputImage;
      base16Scheme = "${pkgs.base16-schemes}/share/themes/gruvbox-dark.yaml";
    };

    home.file.".background-image".source = lib.mkIf config.bundles.dwm.enable outputImage;
    xresources.properties = with config.lib.stylix.colors.withHashtag;
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
