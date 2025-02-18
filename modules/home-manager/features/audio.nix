{ pkgs, ... }:

{
  home.packages = with pkgs; [
    pulsemixer
    pavucontrol
  ];
}
