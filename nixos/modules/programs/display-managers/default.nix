_:
{
  lib,
  ...
}:

with lib;

{
  options.programs.display-managers = {
    ly.enable = mkEnableOption "Enable ly";
  };
}
