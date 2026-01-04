_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.fldigi;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.fldigi ];
  };
}
