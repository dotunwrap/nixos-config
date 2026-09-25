{
  inputs,
  config,
  lib,
  ...
}:
{
  flake.githubActions = inputs.nix-github-actions.lib.mkGithubMatrix {
    checks = lib.recursiveUpdate config.flake.checks config.flake.ciChecks;
  };
}
