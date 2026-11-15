{ config, lib, ... }:
{
  # NOTE: not flake.checks; building every host's closure in parallel is a
  # real OOM risk locally (confirmed once). Only CI's disposable runners build this.
  flake.ciChecks.x86_64-linux = lib.mapAttrs' (
    name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel
  ) config.flake.nixosConfigurations;
}
