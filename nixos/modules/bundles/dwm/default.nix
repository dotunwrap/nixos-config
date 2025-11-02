_:
{
  config,
  lib,
  pkgs,
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
    fonts = {
      packages = with pkgs; [
        corefonts

        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        font-awesome

        garamond-libre

        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
      ];
    };

    programs = {
      window-managers.dwm.enable = true;
      display-managers.ly.enable = true;
    };

    services = {
      displayManager.defaultSession = "dwm";
      flatpak.enable = true;
    };

    xdg.portal = {
      enable = true;
      config.common.default = "*";
      extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
    };
  };
}
