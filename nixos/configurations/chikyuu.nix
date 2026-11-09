_:
{
  config,
  pkgs,
  ...
}:

{
  activeBundles = [
    "base"
    "development"
    "dwm"
    "gaming"
  ];

  fileSystems = {
    "/games" = {
      device = "/dev/disk/by-label/games";
      fsType = "ext4";
      neededForBoot = false;
    };
  };

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
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
  drivers.ffado.enable = true;

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

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  users.users = import ./users/gabby.nix pkgs;
}
