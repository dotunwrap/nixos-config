inputs:
let
  pkgs = import inputs.nixpkgs {
    system = "x86_64-linux";
    config.allowUnfree = true;
  };

  treefmt = import ../treefmt.nix { inherit pkgs; };
in
{
  treefmt = treefmt.check inputs.self;
}
