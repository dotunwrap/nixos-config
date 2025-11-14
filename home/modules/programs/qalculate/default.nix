_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qalculate;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.libqalculate ];
  };
}
