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
  options.bundles.niri = {
    enable = lib.mkEnableOption "The niri bundle.";
  };

  config = lib.mkIf cfg.enable {
    xdg.userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

    programs = {
      bitwarden.enable = lib.mkDefault true;
      freetube.enable = lib.mkDefault true;
      imagemagick.enable = lib.mkDefault true;
      obs-studio.enable = lib.mkDefault true;
      onlyoffice.enable = lib.mkDefault true;
      pavucontrol.enable = lib.mkDefault true;
      protonmail-desktop.enable = lib.mkDefault true;
      protonvpn.enable = lib.mkDefault true;
      qbittorrent.enable = lib.mkDefault true;
      signal.enable = lib.mkDefault true;
      spotify.enable = lib.mkDefault true;
      tor-browser.enable = lib.mkDefault true;
      vesktop.enable = lib.mkDefault true;
      vicinae.enable = lib.mkDefault true;
      wayland-utils.enable = lib.mkDefault true;
      wezterm.enable = lib.mkDefault true;
      wl-clipboard.enable = lib.mkDefault true;
      zen-browser = {
        enable = lib.mkDefault true;
        setAsDefaultBrowser = lib.mkDefault true;
      };
    };

    xdg.mimeApps = {
      enable = true;
      defaultApplications = {
        "application/pdf" = lib.mkDefault "zen-twilight.desktop";
      };
    };

    misc.niri-config.enable = true;

    services = {
      awww.enable = lib.mkDefault true;
      mako.enable = lib.mkDefault true;
      playerctld.enable = lib.mkDefault true;
      swayidle = {
        enable = true;
        events.before-sleep = "";
      };
      swayosd.enable = true;
    };

    home.packages = with pkgs; [
      xwayland-satellite
    ];
  };
}
