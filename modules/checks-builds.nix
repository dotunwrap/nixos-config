{ config, lib, ... }:
{
  # NOTE: deliberately NOT flake.checks: `nix flake check` auto-builds
  # everything under checks.<system>.*, and building every host's full
  # closure in parallel is a real OOM risk on a daily-driver machine
  # (confirmed once). Only consumed by modules/github-actions.nix's CI
  # matrix, on disposable runners.
  flake.ciChecks.x86_64-linux = lib.mapAttrs' (
    name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel
  ) config.flake.nixosConfigurations;
}
