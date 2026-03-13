inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
    "gaming"
  ];

  themes.everforest.enable = true;
  stylix.image = ../../assets/wallpapers/stephen_njoto.png;

  home.stateVersion = "24.11";
} (import ./shared/gabby.nix inputs default)
