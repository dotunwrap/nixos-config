_:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.base;
in

{
  options = {
    bundles.base = {
      enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      at-spi2-atk
    ];

    core = {
      cachix.enable = true;
      flake.enable = true;
      kernel.enable = true;
      nix.enable = true;
    };

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      enableAllFirmware = true;
    };

    programs = {
      dconf.enable = true;
      usbutils.enable = true;
      xdg-utils.enable = true;
      zsh.enable = true;
    };

    security = {
      polkit.enable = true;
    };

    services = {
      dbus = {
        enable = true;
        implementation = "broker";
        packages = with pkgs; [
          xfce.xfconf
          gnome2.GConf
        ];
      };
      gvfs.enable = true;
      openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = false;
          KbdInteractiveAuthentication = false;
          PermitRootLogin = "no";
          AllowUsers = lib.mkDefault [ ];
        };
      };
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
        jack.enable = true;
      };
      printing.enable = true;
      upower.enable = true;
    };

    systemd = {
      user.services.polkit-gnome-authentication-agent-1 = {
        description = "polkit-gnome-authentication-agent-1";
        wantedBy = [ "graphical-session.target" ];
        wants = [ "graphical-session.target" ];
        after = [ "graphical-session.target" ];
        serviceConfig = {
          Type = "simple";
          ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
          Restart = "on-failure";
          RestartSec = 1;
          TimeoutStopSec = 10;
        };
      };
    };
  };
}
