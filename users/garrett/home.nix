{ inputs, outputs, lib, ... }:

{
  imports = [
    outputs.homeManagerModules.default
    inputs.nixvim.homeManagerModules.nixvim
  ];

  programs.git = {
    userName = "Garrett Simpson";
    userEmail = "garrett@dotunwrap.dev";
  };

  programs.zsh.enable = true;
  programs.wezterm.enable = true;
  programs.nixvim = {
    enable = true;
    imports = [ inputs.neve.nixvimModule ];
  };

  myUser = {
    bundles.general.enable = true;
    bundles.desktop.enable = true;

    alacritty.enable = true;
  };

  home = {
    username = "garrett";
    homeDirectory = lib.mkDefault "/home/garrett";
    stateVersion = "24.11";
  };
}
