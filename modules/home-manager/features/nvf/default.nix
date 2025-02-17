{ inputs, ... }:

{
  imports = [
    inputs.nvf.homeManagerModules.default
    ./options.nix
    ./binds.nix
    ./languages.nix
    ./plugins.nix
  ];

  programs.nvf = {
    enable = true;
    settings = {
      vim = {
        theme = {
          enable = true;
          name = "catppuccin";
          style = "mocha";
        };
      };
    };
  };
}
