_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.rofi;
in
{
  config = lib.mkIf cfg.enable {
    programs.rofi = {
      plugins = with pkgs; [
        rofi-calc
        rofi-bluetooth
      ];
    };
  };
}
