_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.arduino-cli;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.arduino-cli ];
  };
}
