{ pkgs, lib, ... }:

{
  config = {
    myUser = {
      # basic desktop modules
      hyprland.enable = true;
      rofi.enable = true;
      feh.enable = lib.mkDefault false;

      # browser modules
      brave.enable = lib.mkDefault true;

      # terminal modules
      wezterm.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;

      # misc modules
      vesktop.enable = lib.mkDefault true;
      typst.enable = lib.mkDefault true;
    };

    home.file = {
      ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
    };
  
    xdg.mimeApps.defaultApplications = {
      "image/*" = ["imv.desktop"];
      "video/png" = ["mpv.desktop"];
      "video/jpg" = ["mpv.desktop"];
      "video/*" = ["mpv.desktop"];
    };

    home.packages = with pkgs; [
      polkit
      polkit_gnome
      lxsession
      pulsemixer
      pavucontrol
      pcmanfm
      libnotify
      mpv
      lm_sensors
      onlyoffice-bin
      easyeffects
      gegl
    ];
  };
}
