_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.magic-wormhole;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.magic-wormhole ];
  };
}
