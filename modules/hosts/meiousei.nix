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

    # Formerly home/modules/themes/catppuccin (flavor=mocha, accent=mauve,
    # subaccent=lavender) + the per-profile `themes.catppuccin.*`/`stylix.image`
    # shared identically by gabby-at-meiousei and nia-at-meiousei -- confirming
    # it's a machine choice. Same catppuccin instance as kaiousei. The shared
    # stylix dispatch lives in modules/defaults.nix.
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        stylix = {
          image = ../../assets/wallpapers/anyb-girl.png;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          override =
            let
              rawColors = config.stylix.base16.mkSchemeAttrs config.stylix.base16Scheme;
            in
            {
              base0D = rawColors.base0E;
              base0E = rawColors.base0D;
            };
          cursor = {
            size = 24;
            package = pkgs.catppuccin-cursors.mochaMauve;
            name = "catppuccin-mocha-mauve-cursors";
          };
        };

        programs.freetube.settings = lib.mkIf config.programs.freetube.enable {
          baseTheme = "catppuccinMocha";
          mainColor = "CatppuccinMochaMauve";
          secColor = "CatppuccinMochaLavender";
          sponsorBlockSponsor.color = "CatppuccinMochaGreen";
          sponsorBlockSelfPromo.color = "CatppuccinMochaYellow";
        };
      };
  };
}
