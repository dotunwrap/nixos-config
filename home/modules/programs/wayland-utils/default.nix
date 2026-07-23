_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wayland-utils;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wayland-utils ];
  };
}
