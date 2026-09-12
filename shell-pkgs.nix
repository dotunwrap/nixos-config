{ pkgs, ... }:
let
  inherit (builtins) attrValues;

  treefmt = import ./treefmt.nix { inherit pkgs; };
in
attrValues {
  inherit (pkgs)
    age
    deadnix
    git
    jq
    just
    nh
    nil
    sops
    statix
    ;
  inherit treefmt;
}
