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
    image = ../../assets/wallpapers/tloz.png;
    opacity = 0.8;
  };

  home.stateVersion = "24.11";
}
// import ./shared/nia.nix inputs default
