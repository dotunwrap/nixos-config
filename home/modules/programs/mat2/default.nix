_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.mat2;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.mat2 ];
  };
}
