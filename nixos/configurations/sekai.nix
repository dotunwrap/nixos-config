_:
{
  config,
  pkgs,
  ...
}:

{
  activeBundles = [
    "base"
    "dwm"
    "gaming"
  ];

  fileSystems = {
    "/games" = {
      device = "/dev/disk/by-label/games";
      fsType = "ext4";
      neededForBoot = false;
    };
    "/mnt/external" = {
      device = "/dev/disk/by-label/external";
      fsType = "ext4";
      neededForBoot = false;
    };
  };

  hardware = {
    graphics = {
      enable = true;
    };
    nvidia = {
      open = false;
      modesetting.enable = true;
      nvidiaSettings = true;
      package = config.boot.kernelPackages.nvidiaPackages.stable;
      powerManagement.enable = true;
      forceFullCompositionPipeline = true;
    };
  };

  boot.kernelParams = [
    "pcie_port_pm=off"
  ];

  services.xserver = {
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
    videoDrivers = [ "nvidia" ];
    displayManager.setupCommands = ''
      ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --mode 5120x1440 --rate 240
    '';
  };

  systemd.services.fix-display-on-resume = {
    description = "Fix Odyssey G9 display after resume";
    after = [
      "sleep.target"
      "display-manager.service"
    ];
    wantedBy = [ "sleep.target" ];

    serviceConfig = {
      Type = "oneshot";
      ExecStart = pkgs.writeShellScript "fix-odyssey-g9" ''
        for i in {1..10}; do
          if ${pkgs.xorg.xrandr}/bin/xrandr --query > /dev/null 2>&1; then
            break
          fi
          sleep 1
        done

        export DISPLAY=:0

        for uid_dir in /run/user/*; do
          # NOTE: ly uses lyxauth instead of Xauthority apparently
          if [ -f "$uid_dir/lyxauth" ]; then
            export XAUTHORITY="$uid_dir/lyxauth"
            
            ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --mode 5120x1440 --rate 240
            exit 0
          fi
        done

        ${pkgs.xorg.xrandr}/bin/xrandr --output HDMI-0 --mode 5120x1440 --rate 240
      '';
    };
  };

  drivers.ffado.enable = true;

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

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  users.users = import ./users/gabby.nix pkgs;

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
  system.stateVersion = "25.05"; # Did you read the comment?
}
