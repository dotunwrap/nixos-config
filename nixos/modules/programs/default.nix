_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    usbutils.enable = mkEnableOption "Enable usbutils";
    xdg-utils.enable = mkEnableOption "Enable xdg-utils";
  };
}

