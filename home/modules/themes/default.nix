{ monolisa, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  options.themes = {
    enable = mkEnableOption "Enable stylix themeing";
    gruvbox-dark.enable = mkEnableOption "Enable gruvbox-dark";
  };

  config = mkIf config.themes.enable {
    stylix = {
      enable = true;
      fonts = {
        # serif = { };
        # sansSerif = { };
        monospace = {
          package = mkDefault monolisa.packages.x86_64-linux.default;
          name = mkDefault "MonoLisa Variable";
        };
        # emoji = { };
      };
    };
  };
}
