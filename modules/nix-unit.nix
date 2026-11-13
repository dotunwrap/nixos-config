{ inputs, ... }:
{
  flake-file.inputs.nix-unit = {
    url = "github:nix-community/nix-unit";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      treefmt-nix.follows = "treefmt-nix";
    };
  };

  imports = [ inputs.nix-unit.modules.flake.default ];
  perSystem.nix-unit.inputs = inputs;
}
