{ dwm, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.window-managers.dwm;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager = {
        dwm = {
          enable = true;
          package = dwm.packages.${system}.default;
        };
      };
    };
  };
}
