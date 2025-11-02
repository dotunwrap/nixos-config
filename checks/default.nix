inputs:
let
  pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;

  callPackage = pkgs.lib.callPackageWith (pkgs // { inherit (inputs) self; });
in
{
  nixfmt = callPackage ./nixfmt.nix { };
}
