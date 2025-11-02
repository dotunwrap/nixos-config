{
  dotunwrap.nixosModules = {
    bundles = ./bundles;
    "bundles/base" = ./bundles/base;
    "bundles/dwm" = ./bundles/dwm;

    "core/cachix" = ./core/cachix;
    "core/flake" = ./core/flake;
    "core/kernel" = ./core/kernel;
    "core/nix" = ./core/nix;

    programs = ./programs;
    "programs/usbutils" = ./programs/usbutils;
    "programs/xdg-utils" = ./programs/xdg-utils;

    "programs/display-managers" = ./programs/display-managers;
    "programs/display-managers/ly" = ./programs/display-managers/ly;

    "programs/window-managers" = ./programs/window-managers;
    "programs/window-managers/dwm" = ./programs/window-managers/dwm;
  };
}
