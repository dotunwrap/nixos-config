_:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.plasma;
in

{
  options.bundles.plasma = {
    enable = lib.mkEnableOption "The KDE Plasma bundle.";
  };

  config = lib.mkIf cfg.enable {
    xdg.userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

    programs = {
      bitwarden.enable = lib.mkDefault true;
      onlyoffice.enable = lib.mkDefault true;
      pavucontrol.enable = lib.mkDefault true;
      protonvpn.enable = lib.mkDefault true;
      qbittorrent.enable = lib.mkDefault true;
      signal.enable = lib.mkDefault true;
      spotify.enable = lib.mkDefault true;
      spotify-player.enable = lib.mkDefault true;
      tor-browser.enable = lib.mkDefault true;
      vesktop.enable = lib.mkDefault true;
      wezterm.enable = lib.mkDefault true;
      zen-browser.enable = lib.mkDefault true;
    };

    services = { };
  };
}
