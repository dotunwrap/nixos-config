_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.libnotify;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = [ pkgs.libnotify ];
  };
}
