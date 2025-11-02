_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.brave;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ brave ];
  };
}
