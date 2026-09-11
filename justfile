osev SYSTEM OUTPUT *ARGS:
  nix eval .#nixosConfigurations.{{SYSTEM}}.{{OUTPUT}} {{ARGS}}

ossw:
  nh os switch

osadd PATH MODULE:
  ./scripts/mkmodule.sh nixos {{PATH}} {{MODULE}}

hmev USER SYSTEM *ARGS:
  nix eval .#homeConfigurations."{{USER}}@{{SYSTEM}}" {{ARGS}}

hmsw:
  nh home switch

hmadd PATH MODULE:
  ./scripts/mkmodule.sh home {{PATH}} {{MODULE}}

switch:
  just ossw
  just hmsw

clean:
  nh clean all --keep 5 --keep-since 7d

check:
  nix flake check --keep-going
