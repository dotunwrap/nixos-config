{
  pkgs,
  ...
}:

{
  home.packages = with pkgs; [
    #(myUtils.forDisplayServer displayServer {
    #  x11 = rofi;
    #  wayland = rofi-wayland;
    #})
    rofi
  ];

  home.file = {
    ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
  };
}
