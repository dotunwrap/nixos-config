{ pkgs, inputs, ... }:

{
  programs.hyprland.enable = true;
  programs.hyprland.package = inputs.hyprland.packages.${pkgs.system}.hyprland;

  services = {
    xserver.enable = true;
    displayManager = {
      defaultSession = "hyprland";
    };
  };
}
