{
  outputs,
  lib,
  ...
}:

{
  imports = [
    outputs.homeManagerModules.default
  ];

  programs.git = {
    userName = "Garrett Simpson";
    userEmail = "garrett@dotunwrap.dev";
  };

  myUser = {
    bundles = {
      general.enable = true;
      desktop.enable = true;
      dev.enable = true;
      work.enable = true;
    };

    # TODO:
    alacritty.enable = true;
  };

  home = {
    username = "garrett";
    homeDirectory = lib.mkDefault "/home/garrett";
    stateVersion = "24.11";
  };
}
