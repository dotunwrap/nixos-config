inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
    "gaming"
  ];

  themes.everforest = {
    enable = true;
    flavor = "dark-hard";
  };
  stylix.image = ../../assets/wallpapers/made-in-abyss.jpg;

  home.stateVersion = "24.11";
} (import ./shared/nia.nix inputs default)
