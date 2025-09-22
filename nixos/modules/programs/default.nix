_: {
  config,
  lib,
  ...
}:

with lib;

{
  config.programs = {
    usbutils.enable = mkEnableOption "Enable usbutils";
    xdg-utils.enable = mkEnableOption "Enable xdg-utils";
  };
}