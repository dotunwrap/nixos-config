_:
{ pkgs }:

{
  nix.settings.substituters = [ "https://cache.nixos.org" ];

  environment.systemPackages = with pkgs; [ cachix ];
}
