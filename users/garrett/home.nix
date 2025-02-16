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

  programs.nixvim = {
    enable = true;
    imports = [ inputs.neve.nixvimModule ];
  };

  myUser = {
    bundles.general.enable = true;
    bundles.desktop.enable = true;
    bundles.dev.enable = true;

    # wezterm is broken for some reason when hyprland has the monitor configured
    # potentially related to scaling somehow?
    wezterm.enable = false;
    alacritty.enable = true;
  };

  home = {
    username = "garrett";
    homeDirectory = lib.mkDefault "/home/garrett";
    sessionVariables.EDITOR = "neovim";
    stateVersion = "24.11";
  };
}
