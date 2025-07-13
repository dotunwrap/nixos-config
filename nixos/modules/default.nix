{
  dotunwrap.nixosModules = {
    bundles = ./bundles;
    "bundles/base" = ./bundles/base;
    "bundles/bspwm" = ./bundles/bspwm;
    "bundles/hyprland" = ./bundles/hyprland;

    "core/cachix" = ./core/cachix.nix;
    "core/flake" = ./core/flake.nix;
    "core/kernel" = ./core/kernal.nix;
    "core/nix" = ./core/nix.nix;

    "programs/usbutils" = ./programs/usbutils.nix;
    "programs/xdg-utils" = ./programs/xdg-utils.nix;
  };
}
