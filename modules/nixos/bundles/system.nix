{ lib, ... }:

{
  mySystem = {
    bootloader.enable = lib.mkDefault true;
    firmware.enable = lib.mkDefault true;
    bluetooth.enable = lib.mkDefault true;
    dconf.enable = lib.mkDefault true;
    pipewire.enable = lib.mkDefault true;
    polkit.enable = lib.mkDefault true;
    fonts.enable = lib.mkDefault true;
    upower.enable = lib.mkDefault true;
    hyprland.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
    sddm.enable = lib.mkDefault false;
    autologin.enable = lib.mkDefault false;
  };

  time.timeZone = lib.mkDefault "America/New_York";
  i18n.defaultLocale = lib.mkDefault "en_US.UTF-8";
}
