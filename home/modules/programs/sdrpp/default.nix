{ nixpkgs-stable, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  stable-pkgs = import nixpkgs-stable {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  cfg = config.programs.sdrpp;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ stable-pkgs.sdrpp ];
  };
}
