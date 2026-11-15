{ inputs, ... }:
{
  flake-file.inputs.devenv = {
    url = "github:cachix/devenv";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };
  };

  # NOTE: devenv.nix's `inputs.nix-auto-follow` resolves against the outer
  # flake here, unlike devenv.yaml's own copy used by the standalone CLI.
  flake-file.inputs.nix-auto-follow = {
    url = "github:fzakaria/nix-auto-follow";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  perSystem =
    { pkgs, ... }:
    let
      inherit (inputs.devenv.lib) mkShell;
    in
    {
      devShells.default = mkShell {
        inherit inputs pkgs;
        modules = [
          (
            # NOTE: `nix flake check` evaluates purely, so devenv's own
            # `builtins.getEnv "PWD"` default is "" and trips its assertion.
            let
              pwd = builtins.getEnv "PWD";
            in
            {
              devenv.root = if pwd != "" then pwd else toString ../.;
            }
          )
          ../devenv.nix
        ];
      };
    };
}
