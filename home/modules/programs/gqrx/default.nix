_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gqrx;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gqrx ];
  };
}
