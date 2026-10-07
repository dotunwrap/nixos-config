_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vial;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.vial ];
  };
}
