_:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.core.cachix;
in
{
  config = lib.mkIf cfg.enable {
    nix.settings.substituters = [ "https://cache.nixos.org" ];

    environment.systemPackages = with pkgs; [ cachix ];
  };
}
