_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.cryptsetup;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.cryptsetup ];
  };
}
