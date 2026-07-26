_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.protonmail-desktop;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.protonmail-desktop ];
  };
}
