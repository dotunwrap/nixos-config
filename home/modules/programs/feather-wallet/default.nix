_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.feather-wallet;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.feather ];
  };
}
