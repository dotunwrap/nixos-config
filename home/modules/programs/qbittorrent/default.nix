_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qbittorrent;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.qbittorrent ];
  };
}
