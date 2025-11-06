_:
{ config, lib, ... }:

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
      brave.enable = true;
      dmenu.enable = true;
      feh.enable = true;
      lxsession.enable = true;
      nushell.enable = true;
      onlyoffice.enable = true;
      pavucontrol.enable = true;
      qutebrowser.enable = true;
      signal.enable = true;
      st.enable = true;
      vesktop.enable = true;
      wezterm.enable = true;
    };

    services = {
      flameshot.enable = true;
    };
  };
}
