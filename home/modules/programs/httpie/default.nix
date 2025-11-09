_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.httpie;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.httpie ];
  };
}
