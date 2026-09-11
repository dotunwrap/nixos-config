_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.sdrpp;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.sdrpp ];
  };
}
