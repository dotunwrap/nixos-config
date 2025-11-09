_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.drivers.ffado;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.ffado ];
  };
}
