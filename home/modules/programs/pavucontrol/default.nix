_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pavucontrol;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pavucontrol
    ];
  };
}
