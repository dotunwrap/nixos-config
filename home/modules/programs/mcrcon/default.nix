_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mcrcon;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mcrcon ];
  };
}
