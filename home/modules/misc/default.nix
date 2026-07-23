_:
{ lib, ... }:
with lib;
{
  options.misc = {
    niri-config.enable = mkEnableOption "Enable the default niri config.";
  };
}
