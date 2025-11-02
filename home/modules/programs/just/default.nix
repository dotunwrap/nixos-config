_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.just_;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.just ];
  };
}
