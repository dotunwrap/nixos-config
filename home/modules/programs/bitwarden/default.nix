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
    nixpkgs.config.permittedInsecurePackages = [
      "electron-39.8.10"
    ];

    home.packages = [
      pkgs.bitwarden-desktop
      pkgs.bitwarden-cli
    ];
  };
}
