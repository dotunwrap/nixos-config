{ inputs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./binds.nix
    ./languages.nix
    ./plugins.nix
    ./themes/catppuccin-mocha.nix  # need to make this modular sooner or later
  ];

  programs.nvf.enable = true;
}
