_:
{
  config,
  lib,
  pkgs,
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
          package = pkgs.dwm.override {
            patches = [ ];
          };
        };
      };
    };
  };
}
