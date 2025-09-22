_: {
  config,
  lib,
  ...
}:

with lib;

{
  config.core = {
    cachix.enable = mkEnableOption "Enable cachix";
    flake.enable = mkEnableOption "Enable flake";
    kernel.enable = mkEnableOption "Enable kernel";
    nix.enable = mkEnableOption "Enable nix";
  };
}