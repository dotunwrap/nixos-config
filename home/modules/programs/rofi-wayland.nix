_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rofi-wayland;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      rofi-wayland
    ];

    home.file = {
      ".local/share/rofi/rofi-bluetooth".source = "${pkgs.rofi-bluetooth}";
    };
  };
}
