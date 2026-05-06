_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.trezor-suite;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.trezor-suite
      pkgs.trezorctl
    ];
  };
}
