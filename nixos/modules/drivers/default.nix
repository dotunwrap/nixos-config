_:
{
  lib,
  ...
}:

with lib;

{
  options.drivers = {
    ffado.enable = mkEnableOption "Enable ffado";
  };
}
