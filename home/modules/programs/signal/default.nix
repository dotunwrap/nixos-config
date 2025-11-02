_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.signal;
in
{
  config = lib.mkIf cfg.enable { home.packages = [ pkgs.signal-desktop ]; };
}
