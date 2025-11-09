_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bitwarden;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [
      pkgs.bitwarden-desktop
      pkgs.bitwarden-cli
    ];
  };
}
