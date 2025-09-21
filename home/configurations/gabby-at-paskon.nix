_: _: {
  nixpkgs.allowedUnfree = [];

  activeBundles = [
    "development"
  ];

  home = {
    username = "gabby";
    homeDirectory = "/home/gabby";
    stateVersion = "25.05";
  };
}
