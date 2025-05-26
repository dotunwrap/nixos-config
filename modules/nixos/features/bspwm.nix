{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    xclip
  ];

  services.xserver = {
    enable = true;
    windowManager = {
      bspwm = {
        enable = true;
      };
    };
    displayManager = {
      startx.enable = true;
    };
  };

  services.displayManager.defaultSession = "bspwm";
}
