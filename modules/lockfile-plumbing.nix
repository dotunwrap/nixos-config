{
  flake-file.inputs = {
    flake-parts.inputs.nixpkgs-lib.follows = "nixpkgs";

    # NOTE: without this, Den's impure fetchTarball fallback for gen/
    # nix-effects has no network access in a sandboxed build and fails.
    gen = {
      url = "github:sini/gen";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        import-tree.follows = "import-tree";
      };
    };

    # NOTE: unused directly, but reachable from nix-unit's sandboxed
    # re-evaluation of Den's module surface; see the `gen` note above.
    nix-effects = {
      url = "github:denful/nix-effects";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        nix-unit.follows = "nix-unit";
      };
    };

    # NOTE: `gen`'s sub-libraries are invisible to nix-unit's sandbox (same
    # issue as `gen`, one level deeper); promote each to a top-level follow.
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

    # NOTE: added just to dedupe the lock file.
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
  };
}
