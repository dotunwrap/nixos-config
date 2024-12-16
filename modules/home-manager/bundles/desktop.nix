{ pkgs, lib, ... }:

{
  config = {
    myUser = {
      hyprland.enable = true;
      brave.enable = lib.mkDefault true;
      alacritty.enable = lib.mkDefault false;
    };

    home.file = {
      ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
    };
  
    qt.enable = true;
    qt.platformTheme = "gtk";
    qt.style.name = "adwaita-dark";
  
    home.sessionVariables = {
      QT_STYLE_OVERRIDE = "adwaita-dark";
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
      adwaita-qt
      pcmanfm
      libnotify

      mpv

      lm_sensors

      wezterm

      onlyoffice-bin
      easyeffects
      gegl
    ];
  };
}
