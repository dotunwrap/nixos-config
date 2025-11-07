_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.steam-tui;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.steamcmd
      pkgs.steam-tui
    ];
  };
}
