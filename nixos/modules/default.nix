{
  dotunwrap.nixosModules = {
    bundles = ./bundles;
    "bundles/base" = ./bundles/base;
    "bundles/bspwm" = ./bundles/bspwm;
    "bundles/hyprland" = ./bundles/hyprland;

    core = ./core;
    "core/cachix" = ./core/cachix;
    "core/flake" = ./core/flake;
    "core/kernel" = ./core/kernel;
    "core/nix" = ./core/nix;

    programs = ./programs;
    "programs/usbutils" = ./programs/usbutils;
    "programs/xdg-utils" = ./programs/xdg-utils;
  };
}
