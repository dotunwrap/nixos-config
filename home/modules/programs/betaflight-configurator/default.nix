_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.betaflight-configurator;
in
{
  config = lib.mkIf cfg.enable {
    nixpkgs.config.permittedInsecurePackages = [
      "nwjs-0.102.1"
    ];

    home.packages = [ pkgs.betaflight-configurator ];
  };
}
