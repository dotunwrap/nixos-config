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
  options.bundles.dwm = {
    enable = lib.mkEnableOption "The dwm bundle. suckless.";
  };

  config = lib.mkIf cfg.enable {
    xdg.userDirs.extraConfig.XDG_SCREENSHOTS_DIR = "${config.home.homeDirectory}/Pictures/Screenshots";

    programs = {
      bitwarden.enable = lib.mkDefault true;
      dmenu.enable = lib.mkDefault true;
      feh.enable = lib.mkDefault true;
      lxsession.enable = lib.mkDefault true;
      nushell.enable = lib.mkDefault true;
      obs-studio = {
        enable = lib.mkDefault true;
        plugins = with pkgs.obs-studio-plugins; [
          droidcam-obs
        ];
      };
      onlyoffice.enable = lib.mkDefault true;
      pavucontrol.enable = lib.mkDefault true;
      qutebrowser.enable = lib.mkDefault true;
      signal.enable = lib.mkDefault true;
      spotify-player.enable = lib.mkDefault true;
      st.enable = lib.mkDefault true;
      tor-browser.enable = lib.mkDefault true;
      vesktop.enable = lib.mkDefault true;
      wezterm.enable = lib.mkDefault true;
      zen-browser.enable = lib.mkDefault true;
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
        "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
      };
    };

    services = {
      flameshot.enable = true;
      picom = {
        enable = true;
        backend = "glx";
        shadow = true;
        inactiveOpacity = 0.8;
        activeOpacity = 0.9;
        opacityRules = [
          "100:class_g = 'qutebrowser'"
          "100:fullscreen"
        ];
        settings = {
          blur = {
            method = "dual_kawase";
            size = 10;
            deviation = 5.0;
          };
        };
      };
    };
  };
}
