_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qFlipper;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.qFlipper ];
  };
}
