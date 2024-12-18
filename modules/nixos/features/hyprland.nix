{ ... }:

{
  programs.hyprland.enable = true;

  services = {
    xserver.enable = true;
    displayManager = {
      defaultSession = "hyprland";
    };
  };
}
