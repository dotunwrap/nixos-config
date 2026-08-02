_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bisq;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.bisq2 ];
  };
}
