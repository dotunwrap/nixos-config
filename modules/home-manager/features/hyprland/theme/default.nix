{ pkgs, lib, inputs, ... }:

{
  imports = [
    inputs.catppuccin.homeManagerModules.catppuccin
  ];

  config = {
    home.packages = with pkgs; [
      libsForQt5.qt5ct
      libsForQt5.qtstyleplugin-kvantum
    ];
    qt = {
      enable = true;
      platformTheme.name = "kvantum";
      style.name = "kvantum";
    };
    catppuccin = {
      enable = true;
      flavor = "frappe";
      pointerCursor = {
        enable = true;
        flavor = "frappe";
        accent = "teal";
      };
    };
    xdg.configFile."rofi/catppuccin-frappe.rasi".source = ./rofi/catppuccin-frappe.rasi;
    xdg.configFile."rofi/config.rasi".source = ./rofi/config.rasi;
  };
}
