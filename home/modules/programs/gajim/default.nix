_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gajim;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.gajim ];
  };
}
