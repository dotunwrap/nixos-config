{ home-manager, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.base;
  inherit (pkgs.stdenv.hostPlatform) system;
in

{
  options = {
    bundles.base = {
      enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.at-spi2-atk
      home-manager.packages.${system}.home-manager
    ];

    hardware = {
      bluetooth = {
        enable = true;
        powerOnBoot = true;
      };
      enableAllFirmware = true;
    };

    nixpkgs.config.allowUnfree = true;

    programs = {
      dconf.enable = true;
      gnupg.enable = true;
      libnotify.enable = true;
      screen.enable = true;
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
          dconf
          xfconf
        ];
      };
      geoclue2.enable = true;
      gvfs.enable = true;
      openssh = {
        enable = true;
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
      tailscale.enable = true;
      udisks2.enable = true;
      upower.enable = true;
    };
  };
}
