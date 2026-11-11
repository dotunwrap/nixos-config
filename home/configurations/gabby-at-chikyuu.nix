inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
  ];

  themes.everforest.enable = true;
  stylix.image = ../../assets/wallpapers/stephen_njoto.png;
} (import ./shared/gabby inputs default)
