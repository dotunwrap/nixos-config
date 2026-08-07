_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vlc;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.vlc ];
  };
}
