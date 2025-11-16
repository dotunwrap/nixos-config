inputs:
{ pkgs, ... }@default:

{
  activeBundles = [
    "development"
    "dwm"
    "gaming"
  ];

  themes = {
    enable = true;
    image = ../../assets/wallpapers/poly.png;
    opacity = 0.8;
  };

  home.stateVersion = "24.11";
}
// import ./shared/gabby.nix inputs default
