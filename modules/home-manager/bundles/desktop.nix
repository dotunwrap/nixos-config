{
  lib,
  #displayServer,
  myUtils,
  ...
}:

{
  config = {
    myUser = {
      # basic desktop modules
      #      ${
      #        myUtils.forDisplayServer displayServer {
      #          x11 = "bspwm";
      #          wayland = "hyprland";
      #        }
      #      }.enable =
      #        true;
      hyprland.enable = lib.mkDefault true;
      rofi.enable = lib.mkDefault true;
      feh.enable = lib.mkDefault false;

      # browser modules
      brave.enable = lib.mkDefault true;

      # terminal modules
      wezterm.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;

      # misc modules
      vesktop.enable = lib.mkDefault true;
      typst.enable = lib.mkDefault true;
      spicetify.enable = lib.mkDefault true;
      polkit.enable = lib.mkDefault true;
      audio.enable = lib.mkDefault true;
      lxsession.enable = lib.mkDefault true;
      libnotify.enable = lib.mkDefault true;
      mpv.enable = lib.mkDefault true;
      imv.enable = lib.mkDefault true;
      onlyoffice.enable = lib.mkDefault true;
      appimage.enable = lib.mkDefault true;
      gimp.enable = lib.mkDefault true;
    };
  };
}
