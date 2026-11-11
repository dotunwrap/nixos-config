{ den, ... }:
{
  den.aspects.meiousei = {
    # TODO: This machine will be moving towards becoming a HTPC. We should
    # build an aspect for this specifically and move away from dwm here.
    includes = [
      den.aspects.gaming
      den.aspects.dwm
      den.aspects.development
    ];

    nixos =
      { config, pkgs, ... }:
      {
        imports = [ ./_hardware/meiousei.nix ];

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
            ${pkgs.xrandr}/bin/xrandr \
              --output DP-2 --primary --mode 2560x1440 --rate 240 --rotate normal \
              --output DP-4 --mode 1920x1080 --rate 74.97 --rotate left --left-of HDMI-0 --scale-from 2560x1440
          '';
          videoDrivers = [ "nvidia" ];
        };

        # Formerly drivers.ffado.
        environment.systemPackages = [ pkgs.ffado ];

        networking = {
          hostName = "meiousei";
          networkmanager.enable = true;
        };

        time.timeZone = "America/New_York";
        i18n.defaultLocale = "en_US.UTF-8";
      };

    # Theme+wallpaper is each user's own choice now (see
    # modules/users/gabby.nix and modules/users/nia.nix) -- not set here.
    # gabby and nia happen to each pick the same catppuccin instance for
    # themselves on this host today, but that's their call, not meiousei's.
  };
}
