inputs:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  spicePkgs = inputs.spicetify-nix.legacyPackages.${pkgs.stdenv.system};
  cfg = config.programs.spicetify;
in

{
  config = lib.mkIf cfg.enable {
    imports = [
      inputs.spicetify-nix.homeManagerModules.spicetify
    ];

    programs.spicetify = {
      enable = true;
      theme = spicePkgs.themes.catppuccin; # TODO: Modularize color schemes
      colorScheme = "mocha";
    };
  };
}
