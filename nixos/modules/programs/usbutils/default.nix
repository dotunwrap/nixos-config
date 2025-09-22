_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.usbutils;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ usbutils ];
  };
}
