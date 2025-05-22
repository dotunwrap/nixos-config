{
  inputs,
  lib,
  config,
  ...
}:
let
  cfg = config.myUser;
in
{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./globals.nix
    ./binds.nix
    ./languages.nix
    ./plugins
    ./themes/catppuccin-mocha.nix # need to make this modular sooner or later
  ];

  programs.nvf = {
    enable = true;
    defaultEditor = true;
    settings = {
      vim = {
        viAlias = true;
        vimAlias = true;
        enableLuaLoader = true;
      };
    };
  };

  programs.zsh.shellAliases = lib.mkIf cfg.zsh.enable {
    neovim = "nvim";
  };
}
