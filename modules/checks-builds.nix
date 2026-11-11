{ config, lib, ... }:
{
  # NOTE: deliberately NOT flake.checks -- `nix flake check`/`just check` auto-builds
  # everything under checks.<system>.*, and building every host's full closure
  # (gaming bundle, SDR stack, etc.) in parallel on a daily-driver machine is a real
  # OOM risk, not a hypothetical one (killed the terminal session once already).
  # Only consumed by modules/github-actions.nix's CI matrix, which runs on disposable
  # GitHub-hosted runners instead of this machine.
  #
  # No separate home-* entries anymore: Home Manager is NixOS-integrated for
  # every profile (home-manager.users.<name> inside each host's own
  # nixosSystem), so each host's own toplevel already covers it.
  flake.ciChecks.x86_64-linux = lib.mapAttrs' (
    name: cfg: lib.nameValuePair "nixos-${name}" cfg.config.system.build.toplevel
  ) config.flake.nixosConfigurations;
}
