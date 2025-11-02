_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.dmenu;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ dmenu ];
  };
}
