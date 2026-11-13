{
  flake-file.inputs = {
    # NOTE: overrides denful/flake-file's modules/dendritic/nixpkgs.nix mkDefault
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # NOTE: must be declared here, not left to denful/den's own dendritic.nix
    # mkDefault -- that default only takes effect once `inputs.den` already
    # resolves, which requires this declaration to exist first. Bootstrap, not
    # redundant.
    den.url = "github:denful/den";

    # Den falls back to an impure fetchTarball for `gen`/`nix-effects` when
    # neither is declared here -- that fetch has no network access inside a
    # sandboxed build (e.g. the nix-unit check) and fails outright. Declaring
    # both ourselves resolves them at normal flake-lock time instead.
    gen = {
      url = "github:sini/gen";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        import-tree.follows = "import-tree";
      };
    };

    # Unused by this repo directly (Den's FX pipeline isn't adopted) but
    # reachable from nix-unit's sandboxed re-evaluation of Den's own module
    # surface -- see the `gen` NOTE above.
    nix-effects = {
      url = "github:denful/nix-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-unit.follows = "nix-unit";
      };
    };

    # `gen`'s own sub-libraries are inputs of `gen`, not of us, and so are
    # invisible to nix-unit's sandbox (same issue as the `gen` NOTE above, one
    # level deeper). Promoting each to a top-level `follows` here makes our
    # own `inputs = inputs;` passthrough reach them too.
    gen-algebra.follows = "gen/gen-algebra";
    gen-aspects.follows = "gen/gen-aspects";
    gen-assemble.follows = "gen/gen-assemble";
    gen-bind.follows = "gen/gen-bind";
    gen-class.follows = "gen/gen-class";
    gen-delivery.follows = "gen/gen-delivery";
    gen-dispatch.follows = "gen/gen-dispatch";
    gen-graph.follows = "gen/gen-graph";
    gen-identity.follows = "gen/gen-identity";
    gen-inspect.follows = "gen/gen-inspect";
    gen-link.follows = "gen/gen-link";
    gen-memo.follows = "gen/gen-memo";
    gen-merge.follows = "gen/gen-merge";
    gen-prelude.follows = "gen/gen-prelude";
    gen-product.follows = "gen/gen-product";
    gen-program.follows = "gen/gen-program";
    gen-rules.follows = "gen/gen-rules";
    gen-schema.follows = "gen/gen-schema";
    gen-scope.follows = "gen/gen-scope";
    gen-select.follows = "gen/gen-select";
    gen-settings.follows = "gen/gen-settings";
    gen-types.follows = "gen/gen-types";
    gen-view.follows = "gen/gen-view";

    nix-unit = {
      url = "github:nix-community/nix-unit";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    nix-github-actions = {
      url = "github:nix-community/nix-github-actions";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # These are added just to dedupe the lock file
    systems.url = "github:nix-systems/default";
    systems-future.url = "github:nix-systems/default/future-26.11";
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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

    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
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

    # Fork of sodiboo/niri-flake; upstream is stale and broken against current nixpkgs
    # (still requires the removed libdisplay-info_0_2), this fork tracks nixpkgs properly.
    niri-flake = {
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
        systems.follows = "systems";
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
}
