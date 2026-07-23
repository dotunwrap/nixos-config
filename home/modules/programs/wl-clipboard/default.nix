_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wl-clipboard;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.wl-clipboard ];
  };
}
