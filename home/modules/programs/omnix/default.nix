_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.omnix;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.omnix ];
  };
}
