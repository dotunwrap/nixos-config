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
      bitwarden.enable = true;
      dmenu.enable = true;
      feh.enable = true;
      lxsession.enable = true;
      nushell.enable = true;
      obs-studio = {
        enable = true;
        plugins = with pkgs.obs-studio-plugins; [
          droidcam-obs
        ];
      };
      onlyoffice.enable = true;
      pavucontrol.enable = true;
      qutebrowser.enable = true;
      signal.enable = true;
      spotify-player.enable = true;
      st.enable = true;
      tor-browser.enable = true;
      vesktop.enable = true;
      wezterm.enable = true;
      zen-browser.enable = true;
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
