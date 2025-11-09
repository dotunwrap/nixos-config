inputs:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  callPackage = pkgs.lib.callPackageWith (pkgs // { inherit (inputs) self; });
in
{
  nixfmt = callPackage ./nixfmt.nix { };
}
