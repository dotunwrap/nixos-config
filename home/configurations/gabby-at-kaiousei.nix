inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "niri"
  ];

  themes.catppuccin = {
    enable = true;
    flavor = "mocha";
    accent = "mauve";
    subaccent = "lavender";
  };
  stylix = {
    image = ../../assets/wallpapers/anyb-girl.png;
  };

  home.stateVersion = "24.11";
} (import ./shared/gabby inputs default)
