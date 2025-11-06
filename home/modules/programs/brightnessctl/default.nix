_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.brightnessctl;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.brightnessctl ];
  };
}
