osev SYSTEM OUTPUT *ARGS:
  nix eval .#nixosConfigurations.{{SYSTEM}}.{{OUTPUT}} {{ARGS}}

ossw:
  sudo nixos-rebuild switch

osadd PATH MODULE:
  ./scripts/mkmodule.sh nixos {{PATH}} {{MODULE}}

hmev USER SYSTEM *ARGS:
  nix eval .#homeConfigurations."{{USER}}@{{SYSTEM}}" {{ARGS}}

hmsw:
  home-manager switch --flake .

hmadd PATH MODULE:
  ./scripts/mkmodule.sh home {{PATH}} {{MODULE}}

switch:
  just ossw
  just hmsw

check:
  nix flake check --keep-going --allow-import-from-derivation
