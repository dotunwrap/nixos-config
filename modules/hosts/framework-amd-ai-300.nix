{ inputs, ... }:
{
  flake-file.inputs.nixos-hardware = {
    url = "github:NixOS/nixos-hardware/master";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  den.aspects.framework-amd-ai-300 = {
    nixos.imports = [ inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series ];
  };
}
