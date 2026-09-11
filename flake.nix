{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };

    # These are added just to dedupe the lock file
    systems.url = "github:nix-systems/default";
    systems-future.url = "github:nix-systems/default/future-26.11";
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    nixvim = {
      url = "github:nix-community/nixvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems-future";
        flake-parts.follows = "flake-parts";
      };
    };

    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    nix = {
      url = "github:nixos/nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.inputs.nixpkgs.follows = "nixpkgs";
      };
    };

    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems-future";
        flake-parts.follows = "flake-parts";
      };
    };

    determinvim = {
      url = "github:dotunwrap/determinvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nixvim.follows = "nixvim";
        systems.follows = "systems-future";
      };
    };

    niavim = {
      url = "github:nyoshe/niavim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nixvim.follows = "nixvim";
        systems.follows = "systems-future";
      };
    };

    suckless = {
      url = "github:dotunwrap/suckless-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };

    monolisa = {
      url = "git+ssh://git@github.com/dotunwrap/monolisa-font-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
    niri-flake = {
      # Fork of sodiboo/niri-flake; upstream is stale and broken against current nixpkgs
      # (still requires the removed libdisplay-info_0_2), this fork tracks nixpkgs properly.
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # vicinae intentionally does NOT follow our nixpkgs: it's a large Qt6/CMake/C++
    # build, so any drift between our nixpkgs pin and vicinae's own guarantees a
    # cache miss against vicinae.cachix.org and a from-source rebuild. We prioritize
    # build speed (real cache hits) over lock file dedup here; see nix-auto-follow's
    # `--ignore vicinae` in devenv.nix.
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.systems.follows = "systems";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs = {
        nixpkgs.follows = "vicinae/nixpkgs";
        vicinae.follows = "vicinae";
      };
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    zennotes = {
      url = "github:ZenNotes/zennotes";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    firefox-addons = {
      url = "gitlab:rycee/nur-expressions?dir=pkgs/firefox-addons";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-overlay = {
      url = "github:sadjow/claude-code-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    claude-desktop = {
      url = "github:heytcass/claude-desktop-linux-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
      };
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
      };
    };
  };

  outputs =
    { flake-parts, ... }@inputs:
    flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
      ];

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
    };
}
