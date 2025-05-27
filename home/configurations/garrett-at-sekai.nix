_: _:

{
  imports = [
    ./garrett.nix
  ];

  nixpkgs.allowedUnfree = [ ];

  activeBundles = [
    "awesome"
    "development"
    "gaming"
    "work"
  ];
}
