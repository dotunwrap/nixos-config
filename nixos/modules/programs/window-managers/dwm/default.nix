{ dwm, ... }:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.window-managers.dwm;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager = {
        dwm = {
          enable = true;
          package = dwm.packages.x86_64-linux.default;
        };
      };
    };
  };
}
