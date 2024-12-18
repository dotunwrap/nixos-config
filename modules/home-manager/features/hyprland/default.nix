{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./keys.nix
    ./theme
  ];

  config = {
    myUser.keymap.enable = lib.mkDefault true;

    wayland.windowManager.hyprland = {
      enable = true;

      settings = {
        general = {
          gaps_in = 5;
          gaps_out = 10;
          border_size = 2;
        };
        decoration = {
          rounding = 5;
        };
        gestures = {
          workspace_swipe = false;
        };
        env = [
          "NIXOS_OZONE_WL,1"
        ];
      };
    };

    programs.waybar.enable = true;
    
    home.packages = with pkgs; [
      pyprland
      hyprpicker
      hyprcursor
      hyprlock
      hypridle
      hyprpaper

      wl-clipboard

      networkmanagerapplet
    ];
  };
}
