inputs:
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.bundles.hyprland;
in
{
  options.bundles.hyprland = {
    enable = lib.mkEnableOption "The hyprland bundle.";
  };

  config = lib.mkIf cfg.enable {
    nix.settings = {
      substituters = [ "https://hyprland.cachix.org" ];
      trusted-substituters = [ "https://hyprland.cachix.org" ];
      trusted-public-keys = [ "hyprland.cachix.org-1:a7pgxzMz7+chwVL3/pzj6jIBMioiJM7ypFP8PwtkuGc=" ];
    };

    programs = {
      hyprland = {
        enable = true;
        package = inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.hyprland;
        portalPackage =
          inputs.hyprland.packages.${pkgs.stdenv.hostPlatform.system}.xdg-desktop-portal-hyprland;
      };
    };

    services = {
      displayManager = {
        ly = {
          enable = true;
        };
        defaultSession = "hyprland";
      };
      xserver.enable = true;
    };
  };
}
