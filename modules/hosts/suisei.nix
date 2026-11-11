{ den, inputs, ... }:
{
  den.aspects.suisei = {
    includes = [
      den.aspects.niri
      den.aspects.development
    ];

    nixos =
      { config, ... }:
      {
        imports = [
          ./_hardware/suisei.nix
          inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
        ];

        networking = {
          hostName = "suisei";
          networkmanager.enable = true;
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
        i18n.defaultLocale = "en_US.UTF-8";

        services = {
          fprintd.enable = true;
          fwupd.enable = true;
        };
      };

    # Theme+wallpaper is nia's own choice now (see modules/users/nia.nix) --
    # not set here.
  };
}
