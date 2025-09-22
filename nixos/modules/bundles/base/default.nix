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
      };
      flatpak.enable = true;
      gvfs.enable = true;
      openssh.enable = true;
      pipewire = {
        enable = true;
        alsa = {
          enable = true;
          support32Bit = true;
        };
        pulse.enable = true;
        jack.enable = true;
      };
      polkit.enable = true;
      printing.enable = true;
      upower.enable = true;
    };
  };
}
