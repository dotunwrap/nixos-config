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
    image = ../../assets/wallpapers/stephen_njoto.png;
    opacity = 0.9;
  };

  home.stateVersion = "24.11";
}
// import ./shared/gabby.nix inputs default
