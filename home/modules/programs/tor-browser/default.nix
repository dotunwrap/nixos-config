_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.tor-browser;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.tor-browser ];
  };
}
