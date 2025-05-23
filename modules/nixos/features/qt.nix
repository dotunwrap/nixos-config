{
  pkgs,
  config,
  ...
}:

{
  environment.systemPackages = with pkgs; [
    (if config.mySystem.hyprland.enable then qt6.qtwayland else null)
    (if config.mySystem.bspwm.enable then qt6 else null)
  ];
}
