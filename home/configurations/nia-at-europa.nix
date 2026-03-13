inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
  ];

  themes.everforest = {
    enable = true;
    flavor = "dark-hard";
  };
  stylix.image = ../../assets/wallpapers/bubbles.jpg;

  home.stateVersion = "24.11";
} (import ./shared/nia.nix inputs default)
