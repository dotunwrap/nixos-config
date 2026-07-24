_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.imagemagick;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.imagemagick ];
  };
}
