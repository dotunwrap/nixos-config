_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.freecad;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.freecad ];
  };
}
