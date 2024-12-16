{
  description = "dotunwrap's NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nixvim = {
      url = "github:nix-community/nixvim";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    neve.url = "github:redyf/Neve";
  };

  outputs = { ... } @ inputs: let
    myUtils = import ./my-utils { inherit inputs; };
  in
    with myUtils; {
      nixosConfigurations = {
        x1 = mkSystem ./hosts/x1;
      };

      homeConfigurations = {
        "garrett@x1" = mkHome "x86_64-linux" ./users/garrett/home.nix;
      };

      homeManagerModules.default = ./modules/home-manager;
      nixosModules.default = ./modules/nixos;
    };
}
