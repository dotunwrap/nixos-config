_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bottles;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bottles ];
  };
}
