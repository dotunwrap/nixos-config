_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.orca-slicer;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.orca-slicer ];
  };
}
