_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    protonup-ng.enable = mkEnableOption "Enable protonup-ng";
    usbutils.enable = mkEnableOption "Enable usbutils";
    xdg-utils.enable = mkEnableOption "Enable xdg-utils";
  };
}
