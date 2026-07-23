inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "niri"
  ];

  themes.monokai.enable = true;
  stylix = {
    image = ../../assets/wallpapers/smile.png;
    cursor.size = 42;
  };

  home.stateVersion = "24.11";
} (import ./shared/gabby.nix inputs default)
