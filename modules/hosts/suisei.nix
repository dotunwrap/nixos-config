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

    # Formerly home/modules/themes/everforest (flavor=hard) + the per-profile
    # `themes.everforest.*`/`stylix.image` in
    # home/configurations/nia-at-suisei.nix. The shared stylix dispatch lives
    # in modules/defaults.nix.
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        stylix.image = ../../assets/wallpapers/bubbles.jpg;
        # polarity defaults to "dark" (modules/defaults.nix).
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-hard.yaml";
      };
  };
}
