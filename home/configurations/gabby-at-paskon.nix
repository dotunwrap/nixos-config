_: _: {
  imports = [
    ./gabby.nix
  ];

  nixpkgs.allowedUnfree = [];

  activeBundles = [
    "development"
  ];
}
