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
    # NOTE: not `nixpkgs.config.permittedInsecurePackages` here -- forbidden under
    # `home-manager.useGlobalPkgs` (now on for every NixOS-integrated profile), and
    # redundant anyway: `nixos/modules/bundles/base` already sets it on the one
    # shared `pkgs` instance every profile now uses.
    home.packages = [ pkgs.betaflight-configurator ];
  };
}
