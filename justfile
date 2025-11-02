osev SYSTEM OUTPUT *ARGS:
  nix eval .#nixosConfigurations.{{SYSTEM}}.{{OUTPUT}} {{ARGS}}

ossw:
  sudo nixos-rebuild switch

hmev USER SYSTEM *ARGS:
  nix eval .#homeConfigurations."{{USER}}@{{SYSTEM}}" {{ARGS}}

hmsw:
  home-manager switch

switch:
  just ossw
  just hmsw

check:
  nix flake check --keep-going --allow-import-from-derivation
