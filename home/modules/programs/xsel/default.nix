_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.xsel;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.xsel ];
  };
}
