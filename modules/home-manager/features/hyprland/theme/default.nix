{ pkgs, inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  config = {
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
    ];

    home.file.".wallpapers/wallpaper.png".source = ../../../../../assets/wallpapers/nixos-wallpaper-catppuccin-mocha.png;
    xdg.configFile."hypr/hyprpaper.conf".text = ''
      preload = ~/.wallpapers/wallpaper.png
      wallpaper = , ~/.wallpapers/wallpaper.png
    '';
    wayland.windowManager.hyprland.settings.exec-once = "hyprpaper";

    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };

    catppuccin = {
      enable = true;
      flavor = "mocha";
      pointerCursor = {
        enable = true;
        flavor = "mocha";
        accent = "teal";
      };
    };

    xdg.configFile."rofi/catppuccin-mocha.rasi".source = ./rofi/catppuccin-mocha.rasi;
    xdg.configFile."rofi/config.rasi".source = ./rofi/config.rasi;
  };
}
