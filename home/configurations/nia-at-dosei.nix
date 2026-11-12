inputs:
{ lib, pkgs, ... }@default:
lib.recursiveUpdate {
  activeBundles = [
    "development"
    "niri"
    "gaming"
    "local_LLM"
  ];

  themes.everforest = {
    enable = true;
    flavor = "hard";
  };
  stylix.image = ../../assets/wallpapers/bubbles.jpg;

  home.stateVersion = "24.11";
} (import ./shared/nia inputs default)
