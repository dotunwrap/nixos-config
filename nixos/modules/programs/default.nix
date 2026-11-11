_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    libnotify.enable = mkEnableOption "Enable libnotify";
    gnupg.enable = mkEnableOption "Enable gnupg";
    usbutils.enable = mkEnableOption "Enable usbutils";
    xdg-utils.enable = mkEnableOption "Enable xdg-utils";
  };
}
