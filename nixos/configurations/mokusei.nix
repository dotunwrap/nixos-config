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

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
    };
    nvidia = {
      modesetting.enable = true;

      nvidiaSettings = true;

      open = true;

      package = config.boot.kernelPackages.nvidiaPackages.stable;
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
  };

  services.xserver = {
    displayManager.sessionCommands = ''
      ${pkgs.xorg.xrandr}/bin/xrandr \
        --output HDMI-0 --primary --mode 1920x1080 --rate 74.97 --rotate normal \
        --output DP-4 --mode 1920x1080 --rate 74.97 --rotate left --left-of HDMI-0
    '';
    videoDrivers = [ "nvidia" ];
  };
  drivers.ffado.enable = true;

  networking = {
    hostName = "mokusei";
    networkmanager.enable = true;
    useDHCP = false;
    interfaces = {
      enp6s0.useDHCP = true;
    };
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  users.users = import ./users/nia.nix pkgs;

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
