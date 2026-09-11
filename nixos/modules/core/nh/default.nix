_:
{
  lib,
  ...
}:
{
  config = {
    # programs.nh already ships its own enable/clean options upstream (see the
    # "programs.just_" collision note in CLAUDE.md for why we don't re-wrap
    # those under our own programs.<name>.enable convention here), so this
    # module just turns them on directly, same as core/nix does for nix.gc.
    programs.nh = {
      enable = true;
      flake = "/etc/nixos";

      clean = {
        enable = true;
        dates = "weekly";
        extraArgs = "--keep 5 --keep-since 7d";
      };
    };

    # nh clean all already covers generation/gc cleanup on its own schedule;
    # leaving nix.gc.automatic on too just duplicates the work and trips the
    # warning programs.nh emits when both are enabled.
    nix.gc.automatic = lib.mkForce false;
  };
}
