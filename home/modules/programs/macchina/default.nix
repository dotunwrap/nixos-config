_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.macchina;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.macchina ];
  };
}
