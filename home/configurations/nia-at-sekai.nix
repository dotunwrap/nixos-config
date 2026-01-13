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
    image = ../../assets/wallpapers/tloz.jpg;
    opacity = 0.8;
  };

  home.stateVersion = "24.11";
}
// import ./shared/nia.nix inputs default
