{
  inputs,
  config,
  lib,
  ...
}:
let
  cfg = config.dotunwrap.homeManagerModules;

  inherit (import ./module-helpers.nix lib inputs) submodule;

  modules = builtins.mapAttrs (_: config: config.wrappedModule) cfg;
in
{
  options = {
    dotunwrap.homeManagerModules = lib.mkOption {
      type = lib.types.attrsOf submodule;
    };
  };

  config.flake.homeManagerModules = modules;
}
