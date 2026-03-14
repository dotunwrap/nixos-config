inputs:
{ lib, pkgs, ... }@default:
# TODO: Remove Nia's account from this machine.
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "dwm"
    "gaming"
  ];

  themes.everforest = {
    enable = true;
    flavor = "hard";
  };
  stylix.image = ../../assets/wallpapers/tloz.jpg;

  home.stateVersion = "24.11";
} (import ./shared/nia.nix inputs default)
