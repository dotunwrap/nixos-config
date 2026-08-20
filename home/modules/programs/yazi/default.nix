{ yazi, ... }:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.yazi;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = lib.mkIf cfg.enable {
    # NOTE: This silences an eval warning for Yazi on systems with home.stateVersion being less than 26.05
    programs.yazi = {
      package = yazi.packages.${system}.default; # Use the bleeding edge build from Yazi upstream
      shellWrapperName = "y";
    };
  };
}
