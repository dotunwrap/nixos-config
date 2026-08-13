_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.betaflight-configurator;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.betaflight-configurator ];
  };
}
