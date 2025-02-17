{ pkgs, lib, ... }:

{
  imports = [
    ./keys.nix
    ./waybar
    ./theme
  ];

  config = {
    myUser.keymap.enable = lib.mkDefault true;

    home.packages = with pkgs; [
      pyprland
      hyprpicker
      hyprlock
      hypridle
      hyprcursor
      hyprpaper

      wl-clipboard

      networkmanagerapplet
    ];

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
          "col.active_border" = "rgba(89b4faee) rgba(94e2d5ee) 45deg";
        };

        exec-once = [
          "hyprpaper"
          "waybar"
        ];

        monitor = ", preferred, auto, 1";

        decoration = {
          rounding = 8;
        };

        gestures = {
          workspace_swipe = true;
        };

        env = [
          "NIXOS_OZONE_WL,1"
        ];
      };
    };
  };
}
