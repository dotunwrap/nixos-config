{
  inputs,
  config,
  lib,
  ...
}:
{
  flake-file.inputs.nix-github-actions = {
    url = "github:nix-community/nix-github-actions";
    inputs.nixpkgs.follows = "nixpkgs";
  };

  flake.githubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
    checks = lib.recursiveUpdate config.flake.checks config.flake.ciChecks;
  };
}
