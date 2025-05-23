{ ... }:

{
  services.xserver = {
    enable = true;
    windowManager = {
      bspwm = {
        enable = true;
      };
    };
    displayManager.defaultSession = "bspwm";
  };
}
