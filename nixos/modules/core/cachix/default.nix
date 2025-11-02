_:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  cfg = config.core.cachix;
  folder = ./caches;
  toImport = name: _: folder + ("/" + name);
  filterCaches = key: value: value == "regular" && lib.hasSuffix ".nix" key;
  imports = lib.mapAttrsToList toImport (lib.filterAttrs filterCaches (builtins.readDir folder));
in
{
  config = lib.mkIf cfg.enable {
    inherit imports;
    nix.settings.substituters = [ "https://cache.nixos.org" ];

    environment.systemPackages = with pkgs; [ cachix ];
  };
}
