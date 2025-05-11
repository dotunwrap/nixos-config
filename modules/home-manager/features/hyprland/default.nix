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
          "col.active_border" = "rgba(94e2d5ee) rgba(94e2d5ee) 45deg";
        };

        exec-once = [
          "hyprpaper"
          "waybar"
        ];

        monitor = [
          "eDP-1, preferred, 0x0, 1"
          "HDMI-A-1, 1920x1080@60, -1920x0, 1"
          "DP-2, 1920x1080@60, -3000x0, 1, transform, 1"
        ];

        decoration = {
          rounding = 8;
        };

        gestures = {
          workspace_swipe = true;
        };

        env = [
          "NIXOS_OZONE_WL,1"
          "MOZ_ENABLE_WAYLAND,1"
        ];
      };
    };
  };
}
