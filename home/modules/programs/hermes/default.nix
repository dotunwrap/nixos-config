{ hermes-agent, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.hermes;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ hermes-agent.packages.${system}.default ];
  };
}
