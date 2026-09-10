{ nix-auth, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  cfg = config.programs.nix-auth;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ nix-auth.packages.${system}.default ];
  };
}
