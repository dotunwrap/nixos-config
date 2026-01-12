_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.protonvpn;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.protonvpn-gui ];
  };
}
