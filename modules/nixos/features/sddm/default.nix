{ pkgs, lib, ... }:
{
  services.xserver = {
    enable = true;
    displayManager = {
      sddm.enable = lib.mkDefault true;
    };
  };

  environment.systemPackages = with pkgs; [
    libsForQt5.qt5.qtquickcontrols2
    libsForQt5.qt5.qtgraphicaleffects
  ];
}
