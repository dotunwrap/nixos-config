_:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.niri;
in

{
  options = {
    bundles.niri = {
      enable = lib.mkEnableOption "The niri bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
      corefonts

      noto-fonts
      noto-fonts-cjk-sans
      noto-fonts-color-emoji

      font-awesome

      garamond-libre

      nerd-fonts.jetbrains-mono
      nerd-fonts.fira-code
      nerd-fonts.symbols-only
    ];

    programs = {
      niri.enable = true;
      display-managers.ly.enable = true;
    };

    services = {
      displayManager.defaultSession = "niri";
    };

    xdg.portal = {
      enable = true;
      extraPortals = with pkgs; [
        xdg-desktop-portal-gtk
        xdg-desktop-portal-gnome
      ];
      config.niri = {
        default = [ "gtk" ];
        "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
        "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
      };
    };

    security.soteria.enable = true;
  };
}
