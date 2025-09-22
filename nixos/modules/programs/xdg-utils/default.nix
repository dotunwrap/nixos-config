_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xdg-utils;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      xdg-utils
    ];
  };
}
