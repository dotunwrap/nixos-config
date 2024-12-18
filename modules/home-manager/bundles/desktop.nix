{ pkgs, lib, ... }:

{
  config = {
    myUser = {
      hyprland.enable = true;
      rofi.enable = true;
      brave.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;
      wezterm.enable = lib.mkDefault true;
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
      feh
      polkit
      polkit_gnome
      lxsession
      pulsemixer
      pavucontrol
      pcmanfm
      libnotify

      btop

      mpv

      lm_sensors

      onlyoffice-bin
      easyeffects
      gegl
    ];
  };
}
