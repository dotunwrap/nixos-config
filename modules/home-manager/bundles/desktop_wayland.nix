{ lib, ... }:

{
  myUser = {
    hyprland.enable = lib.mkDefault true;
  };
}
