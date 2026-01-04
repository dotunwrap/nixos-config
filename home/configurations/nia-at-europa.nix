inputs:
{ pkgs, ... }@default:
{
  activeBundles = [
    "development"
    "dwm"
  ];

  home.stateVersion = "24.11";
}
// import ./shared/nia.nix inputs default
