_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.st;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.st ];
  };
}
