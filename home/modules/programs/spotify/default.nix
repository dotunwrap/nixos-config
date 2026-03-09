_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.spotify;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.spotify ];
  };
}
