inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
  ];

  themes.monokai.enable = true;
  stylix = {
    image = ../../assets/wallpapers/smile.png;
    cursor.size = 42;
  };

  xresources.properties = {
    "Xft.dpi" = "150";
  };

  home.stateVersion = "24.11";
} (import ./shared/gabby.nix inputs default)
