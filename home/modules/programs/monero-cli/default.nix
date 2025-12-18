_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.monero-cli;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.monero-cli ];
  };
}
