_:
{
  lib,
  ...
}:

with lib;

{
  options.programs.window-managers = {
    dwm.enable = mkEnableOption "Enable dwm";
  };
}
