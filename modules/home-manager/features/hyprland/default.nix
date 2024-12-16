{
  pkgs,
  lib,
  ...
}: {
  imports = [
    ./keys.nix
  ];

  config = {
    myUser.keymap.enable = lib.mkDefault true;

    wayland.windowManager.hyprland = {
      #plugins = 
      #[]
      #++ lib.optional;

      enable = true;
    };
    
    home.packages = with pkgs; [
      wl-clipboard

      networkmanagerapplet

      rofi-wayland
    ];
  };
}
