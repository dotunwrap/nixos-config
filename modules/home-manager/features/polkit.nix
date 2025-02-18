{ pkgs, ... }:

{
  home.packages = with pkgs; [
    polkit
    polkit_gnome
  ];
}
