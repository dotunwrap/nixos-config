{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    flake-parts.url = "github:hercules-ci/flake-parts";
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";

    nix.url = "github:nixos/nix";
    nix.inputs.nixpkgs.follows = "nixpkgs";
    nix.inputs.flake-parts.follows = "flake-parts";

    # TODO: Enable sops
    # sops-nix.url = "github:Mic92/sops-nix";
    # sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    programs-db.url = "github:wamserma/flake-programs-sqlite";
    programs-db.inputs.nixpkgs.follows = "nixpkgs";

    stylix.url = "github:nix-community/stylix";
    stylix.inputs.nixpkgs.follows = "nixpkgs";

    determinvim.url = "github:dotunwrap/determinvim";
    determinvim.inputs.nixpkgs.follows = "nixpkgs";
    determinvim.inputs.flake-parts.follows = "flake-parts";

    niavim.url = "github:nyoshe/niavim";
    niavim.inputs.nixpkgs.follows = "nixpkgs";
    niavim.inputs.flake-parts.follows = "flake-parts";

    suckless.url = "github:dotunwrap/suckless-nix";
    suckless.inputs.nixpkgs.follows = "nixpkgs-stable";
    suckless.inputs.flake-parts.follows = "flake-parts";

    monolisa.url = "git+ssh://git@github.com/dotunwrap/monolisa-font-nix";
    monolisa.inputs.nixpkgs.follows = "nixpkgs";
    monolisa.inputs.flake-parts.follows = "flake-parts";

    niri-flake.url = "github:sodiboo/niri-flake";
    niri-flake.inputs.nixpkgs.follows = "nixpkgs";

    vicinae.url = "github:vicinaehq/vicinae";
    vicinae-extensions.url = "github:vicinaehq/extensions";
    vicinae-extensions.inputs.nixpkgs.follows = "nixpkgs";

    zen-browser.url = "github:0xc000022070/zen-browser-flake";
    zen-browser.inputs.nixpkgs.follows = "nixpkgs";
    zen-browser.inputs.home-manager.follows = "home-manager";

    firefox-addons.url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
    firefox-addons.inputs.nixpkgs.follows = "nixpkgs";

    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";

    claude-code-overlay.url = "github:sadjow/claude-code-nix";
    claude-code-overlay.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

      debug = true;

      imports = [
        ./parts/auxillary.nix
        ./parts/home-configs.nix
        ./parts/home-modules.nix
        ./parts/nixos-modules.nix
        ./parts/system-configs.nix

        ./nixos/configurations
        ./home/configurations

        ./home/modules
        ./nixos/modules
      ];

      flake = {
        checks.x86_64-linux = import ./checks inputs;
      };
    };
}
