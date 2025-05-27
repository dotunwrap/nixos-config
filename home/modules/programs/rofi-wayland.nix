_:
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi-wayland
  ];

  home.file = {
    ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
  };
}
