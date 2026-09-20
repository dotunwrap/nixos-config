_:
{ pkgs, ... }:
let
  caches = import ./caches.nix;
in
{
  nix.settings = {
    substituters = [ "https://cache.nixos.org" ] ++ builtins.map (c: c.url) caches;
    trusted-public-keys = builtins.map (c: c.key) caches;
  };

  environment.systemPackages = with pkgs; [ cachix ];
}
