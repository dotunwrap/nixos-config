_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gimp;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ gimp ];
  };
}
