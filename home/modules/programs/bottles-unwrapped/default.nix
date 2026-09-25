_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bottles-unwrapped;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bottles-unwrapped ];
  };
}
