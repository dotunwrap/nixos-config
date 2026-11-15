{ inputs, ... }:
{
  flake-file.inputs.devenv = {
    url = "github:cachix/devenv";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };
  };

  # devenv.nix's `inputs.nix-auto-follow` resolves against the outer flake's
  # inputs when loaded as a `devenv.lib.mkShell` module (as opposed to
  # devenv.yaml's own copy, used only when the standalone `devenv` CLI
  # evaluates devenv.nix directly).
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
            # `nix flake check` evaluates this purely, where `$PWD` is unreadable;
            # devenv's own default (builtins.getEnv "PWD") would then be "" and trip
            # its "not able to determine the current directory" assertion. Falling
            # back to the repo path keeps `just check` green without affecting real
            # shell entry, where $PWD is readable (see
            # https://devenv.sh/guides/using-with-flakes/).
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
