_:
{ pkgs, ... }:

{
  home.packages = with pkgs; [
    rofi
  ];

  home.file = {
    ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
  };
}
