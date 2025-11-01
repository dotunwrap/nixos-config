_:
{
  config,
  lib,
  ...
}:

let
  cfg = config.bundles.dwm;
in

{
  options = {
    bundles.dwm = {
      enable = lib.mkEnableOption "The dwm bundle. suckless.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      window-managers.dwm.enable = true;
      display-managers.ly.enable = true;
    };

    services = {
      xserver.displayManager.defaultSession = "dwm";
      flatpak.enable = true;
    };
  };
}
