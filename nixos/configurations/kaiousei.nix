{ nixos-hardware, ... }:
{ config, pkgs, ... }:
{
  imports = [
    nixos-hardware.nixosModules.framework-amd-ai-300-series
  ];

  activeBundles = [
    "development"
    "niri"
  ];

  hardware.framework.enableKmod = true;

  networking = {
    hostName = "kaiousei";
    networkmanager.enable = true;
    # NOTE: Removed DHCP configuration for my interfaces as NetworkManager handles this by default.
    nftables.enable = true;
    firewall = {
      enable = true;

      trustedInterfaces = [ config.services.tailscale.interfaceName ];
      allowedUDPPorts = [ config.services.tailscale.port ];
    };
  };

  systemd.services.tailscaled.serviceConfig.Environment = [
    "TS_DEBUG_FIREWALL_MODE=nftables"
  ];

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  services = {
    fprintd.enable = true;
    fwupd.enable = true;
  };

  users.users = import ./users/gabby.nix pkgs;
}
