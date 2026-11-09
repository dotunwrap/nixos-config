osev SYSTEM OUTPUT *ARGS:
  nix eval .#nixosConfigurations.{{SYSTEM}}.{{OUTPUT}} {{ARGS}}

ossw:
  nh os switch

osadd PATH MODULE:
  ./scripts/mkmodule.sh nixos {{PATH}} {{MODULE}}

# NOTE: standalone homeConfigurations.* is retired -- Home Manager now
# activates as part of `just ossw` (home-manager.users.<name> inside each
# host's own nixosSystem). Full justfile cleanup deferred; this is a minimal
# stopgap so these don't error outright.
hmev USER SYSTEM *ARGS:
  @echo "no longer applicable -- Home Manager is now part of 'just ossw'"

hmsw:
  @echo "no longer applicable -- Home Manager is now part of 'just ossw'"

hmadd PATH MODULE:
  ./scripts/mkmodule.sh home {{PATH}} {{MODULE}}

switch:
  just ossw

clean:
  nh clean all --keep 5 --keep-since 7d

check:
  nix flake check --keep-going
