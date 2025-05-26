{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.dotunwrap.nixosModules;

  inherit (import ./module-helpers.nix lib inputs) submodule;

  modules = builtins.mapAttrs (_: config: config.wrappedModule) cfg;
in
{
  options = {
    dotunwrap.nixosModules = lib.mkOption {
      type = lib.types.attrsOf submodule;
    };
  };

  config.flake.nixosModules = modules;
}
