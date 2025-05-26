{
  description = "dotunwrap's NixOS config flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    hyprland.url = "github:hyprwm/Hyprland";
    hyprland-plugins = {
      url = "github:hyprwm/hyprland-plugins";
      inputs.hyprland.follows = "hyprland";
    };

    nvf = {
      url = "github:notashelf/nvf";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    catppuccin.url = "github:catppuccin/nix";

    spicetify-nix.url = "github:Gerg-L/spicetify-nix";
  };

  outputs =
    inputs:
    let
      myUtils = import ./my-utils { inherit inputs; };
    in
    with myUtils;
    {
      nixosConfigurations = {
        x1 = mkSystem ./hosts/x1;
        sekai = mkSystem ./hosts/sekai;
      };

      homeConfigurations = {
        "garrett@x1" = mkHome "x86_64-linux" "wayland" ./users/garrett/home.nix;
        "garrett@sekai" = mkHome "x86_64-linux" "x11" ./users/garrett/home.nix;
      };

      homeManagerModules.default = ./modules/home-manager;
      nixosModules.default = ./modules/nixos;
    };
}
