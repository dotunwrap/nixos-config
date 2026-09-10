_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.secretspec;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.secretspec ];
  };
}
