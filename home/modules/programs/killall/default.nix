_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.killall;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ killall ];
  };
}
