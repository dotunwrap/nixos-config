{ config, lib, ... }:
{
  # NOTE: deliberately NOT flake.checks -- `nix flake check`/`just check` auto-builds
  # everything under checks.<system>.*, and building every host's full closure
  # (gaming bundle, SDR stack, etc.) in parallel on a daily-driver machine is a real
  # OOM risk, not a hypothetical one (killed the terminal session once already).
  # Only consumed by modules/github-actions.nix's CI matrix, which runs on disposable
  # GitHub-hosted runners instead of this machine.
  flake.ciChecks.x86_64-linux =
    (lib.mapAttrs' (
      name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel
    ) config.flake.nixosConfigurations)
    // (lib.mapAttrs' (
      name: cfg: lib.nameValuePair "home-${lib.replaceStrings [ "@" ] [ "-" ] name}" cfg.activationPackage
    ) config.flake.homeConfigurations);
}
