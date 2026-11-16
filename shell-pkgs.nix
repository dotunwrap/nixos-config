{ inputs, pkgs, ... }:
let
  inherit (builtins) attrValues;
  inherit (pkgs.stdenv.hostPlatform) system;

  autoFollow = inputs.nix-auto-follow.packages.${system}.default;
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
  inherit treefmt autoFollow;
}
