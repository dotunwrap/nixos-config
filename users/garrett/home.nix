{ outputs, lib, ... }:

{
  imports = [
    outputs.homeManagerModules.default
  ];

  programs.git = {
    userName = "Garrett Simpson";
    userEmail = "garrett@dotunwrap.dev";
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
