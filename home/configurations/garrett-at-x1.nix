_: _:

{
  imports = [
    ./garrett.nix
  ];

  nixpkgs.allowedUnfree = [ ];

  activeBundles = [
    "development"
    "hyprland"
    "work"
  ];
}
