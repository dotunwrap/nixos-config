_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bambu-studio;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bambu-studio ];
  };
}
