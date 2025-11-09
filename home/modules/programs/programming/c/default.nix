_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.programming.c;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ gcc ];
  };
}
