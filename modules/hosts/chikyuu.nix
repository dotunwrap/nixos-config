{ den, ... }:
{
  den.aspects.chikyuu = {
    includes = [
      den.aspects.gaming
      den.aspects.dwm
    ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ ./_hardware/chikyuu.nix ];

        fileSystems."/games" = {
          device = "/dev/disk/by-label/games";
          fsType = "ext4";
          neededForBoot = false;
        };

        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        boot = {
          kernelModules = [
            "kvm-amd"
            "v4l2loopback"
          ];
          extraModulePackages = with pkgs.linuxPackages; [ v4l2loopback ];
          extraModprobeConfig = ''
            options v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1
          '';
          initrd.kernelModules = [ "amdgpu" ];
        };

        # Formerly drivers.ffado.
        environment.systemPackages = [ pkgs.ffado ];

        services = {
          monero = {
            enable = true;
            rpc = {
              address = "0.0.0.0";
              port = 18081;
              restricted = false;
            };
            extraConfig = ''
              confirm-external-bind=1

              rpc-restricted-bind-ip=0.0.0.0
              rpc-restricted-bind-port=18089

              no-igd=1

              enable-dns-blocklist=1
              no-zmq=1
            '';
          };
          xserver = {
            resolutions = [
              {
                x = 5120;
                y = 1440;
              }
            ];
            # WARNING: This will BREAK the display server entirely if the Odyssey G9 is out of game mode for some reason.
            monitorSection = ''
              Option "PreferredMode" "5120x1440"
              Option "TargetRefresh" "240"
            '';
            deviceSection = ''
              Option "TearFree" "false"
              Option "VariableRefresh" "true"
            '';
            videoDrivers = [ "amdgpu" ];
          };
        };

        networking = {
          hostName = "chikyuu";
          networkmanager.enable = true;
          nftables.enable = true;
          firewall = {
            enable = true;
            trustedInterfaces = [ config.services.tailscale.interfaceName ];
            allowedTCPPorts = [ 18080 ];
            allowedUDPPorts = [ config.services.tailscale.port ];
            interfaces = {
              enp8s0.allowedTCPPorts = [
                18081
                18089
              ];
              tailscale0.allowedTCPPorts = [
                18081
                18089
              ];
            };
          };
        };

        systemd.services.tailscaled.serviceConfig.Environment = [
          "TS_DEBUG_FIREWALL_MODE=nftables"
        ];

        time.timeZone = "America/New_York";
        i18n.defaultLocale = "en_US.UTF-8";
      };

    # Formerly home/modules/themes/everforest + the per-profile
    # `themes.everforest.enable`/`stylix.image` in
    # home/configurations/gabby-at-chikyuu.nix. Host-scoped (provides.to-users)
    # rather than user-scoped since it's a machine-appearance choice, not a
    # personal one -- confirmed by kaiousei/meiousei sharing an identical
    # theme+wallpaper across their (different) users. The shared stylix
    # dispatch (enable/polarity/fonts/cursor-defaults/targets) lives in
    # modules/defaults.nix; this is just the everforest-specific part.
    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        stylix.image = ../../assets/wallpapers/stephen_njoto.png;
        # polarity defaults to "dark" (modules/defaults.nix); everforest has
        # no light-mode medium-flavor scheme upstream yet, so that branch
        # would need modules/hosts/everforest-light-medium.yaml if polarity
        # were ever overridden to "light" here.
        stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/everforest-dark-medium.yaml";
      };
  };
}
