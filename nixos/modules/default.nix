{
  dotunwrap.nixosModules = {
    bundles = ./bundles;
    "bundles/base" = ./bundles/base;
    "bundles/bspwm" = ./bundles/bspwm;
    "bundles/hyprland" = ./bundles/hyprland;

    "core/flake" = ./core/flake.nix;
    "core/kernel" = ./core/kernal.nix;
    "core/nix" = ./core/nix.nix;

    "services/audio/pipewire" = ./services/audio/pipewire.nix;
    "services/display-manager/ly" = ./services/display-manager/ly.nix;
  };
}
