_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    gnupg.enable = mkEnableOption "Enable gnupg";
    protonup-ng.enable = mkEnableOption "Enable protonup-ng";
    usbutils.enable = mkEnableOption "Enable usbutils";
    xdg-utils.enable = mkEnableOption "Enable xdg-utils";
  };
}
