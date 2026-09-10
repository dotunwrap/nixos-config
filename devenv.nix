{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) system;

  autoFollow = lib.getExe' inputs.nix-auto-follow.packages.${system}.default "auto-follow";

  treefmt = import ./treefmt.nix { inherit pkgs; };
in
{
  # https://devenv.sh/packages/
  packages = with pkgs; [
    git
    just
    jq
    sops
    nil
    statix
    deadnix
    treefmt
    inputs.nix-auto-follow.packages.${system}.default
  ];

  # https://devenv.sh/languages/
  languages = {
    nix.enable = true;
    shell.enable = true;
  };

  # https://devenv.sh/tests/
  enterTest = ''
    echo "Running static checks"
    treefmt --fail-on-change --no-cache
    statix check .
    deadnix --fail --no-lambda-pattern-names .
  '';

  # https://devenv.sh/git-hooks/
  git-hooks.hooks = {
    action-validator.enable = true;
    actionlint.enable = true;
    check-merge-conflicts.enable = true;
    nil.enable = true;
    shellcheck.enable = true;
    statix.enable = true;

    # NixOS/home-manager modules and flake-parts perSystem are called by a framework
    # with a fixed argument set, so unused module args are expected and shouldn't be
    # flagged as dead code (same reasoning as nixpkgs callPackage).
    deadnix = {
      enable = true;
      settings.noLambdaPatternNames = true;
    };

    treefmt = {
      enable = true;
      packageOverrides.treefmt = treefmt;
    };

    # Fails the commit if flake.lock's `inputs.*.follows` aren't deduplicated,
    # prompting a manual `just update` (or `auto-follow --in-place`) run.
    nix-auto-follow = {
      enable = true;
      name = "nix-auto-follow";
      description = "Check flake.lock inputs.*.follows are deduplicated via nix-auto-follow";
      entry = "${autoFollow} --check";
      files = "^flake\\.lock$";
      pass_filenames = false;
    };
  };

  # See full reference at https://devenv.sh/reference/options/
}
