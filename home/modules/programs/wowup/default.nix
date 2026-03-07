_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wowup;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wowup-cf ];
  };
}
