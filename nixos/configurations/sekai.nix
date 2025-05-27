{ self, ... }@inputs:
{
  config,
  pkgs,
  lib,
  ...
}:

{
  activeBundles = [ ];

  networking = {
    hostName = "sekai";
    networkmanager.enable = true;
    useDHCP = false;
    interfaces = {
      enp6s0.useDHCP = true;
      wlp13s0.useDHCP = true;
    };
  };

  time.timeZone = "America/New_York";

  services = {
    displayManager.ly.enable = true;
    xserver.windowManager.bspwm.enable = true;
    flatpak.enable = true;
    printing.enable = true;
    dbug.packages = with pkgs; [ dconf ];
  };

  hardware = {
    bluetooth.enable = true;
  };

  nix = {

  };

  i18n = {

  };

  environment.systemPackages = with pkgs; [

  ];

  users.users = {

  };

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "24.11"; # Did you read the comment?
}
