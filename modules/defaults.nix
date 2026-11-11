{ inputs, lib, ... }:
{
  # Formerly nixos/modules/bundles/base -- unconditional on every host, so it
  # moves to den.default.nixos (broadcast to every host) rather than becoming
  # an aspect some host would need to `includes`.
  den.default.nixos =
    { pkgs, ... }:
    {
      system.stateVersion = lib.mkDefault "25.05";

      environment.systemPackages = [
        pkgs.at-spi2-atk
        inputs.home-manager.packages.${pkgs.stdenv.hostPlatform.system}.home-manager
      ];

      hardware = {
        bluetooth = {
          enable = true;
          powerOnBoot = true;
          settings = {
            General = {
              Enable = "Source,Sink,Media,Socket";
              Experimental = true;
              FastConnectable = true;
            };
            Policy.AutoEnable = true;
          };
        };
        enableAllFirmware = true;
      };

      nixpkgs.config.allowUnfree = true;
      # NOTE: needed here, not just at home/modules/programs/betaflight-configurator
      # (which used to set this itself) -- forbidden per-user under
      # home-manager.useGlobalPkgs, same reasoning as allowUnfree above.
      nixpkgs.config.permittedInsecurePackages = [ "nwjs-0.102.1" ];

      programs = {
        dconf.enable = true;
        gnupg.enable = true;
        libnotify.enable = true;
        screen.enable = true;
        usbutils.enable = true;
        xdg-utils.enable = true;
        zsh.enable = true;
      };

      security.polkit.enable = true;

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
        printing.enable = true;
        tailscale.enable = true;
        udisks2.enable = true;
        upower.enable = true;
      };
    };

  # Formerly home/modules/bundles/base -- unconditional on every home-manager
  # user (it was force-enabled for every profile via home/modules/misc/home,
  # bypassing activeBundles entirely; den.default.homeManager achieves the
  # same "every user" broadcast natively). `monolisa.package` keeps the same
  # per-user override point the old `bundles.base.monolisaVersion` option
  # gave nia's profile (see home/configurations/shared/nia/default.nix).
  den.default.homeManager =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {
      options.monolisa.package = lib.mkOption {
        type = lib.types.package;
        default = inputs.monolisa.packages.${pkgs.stdenv.hostPlatform.system}.default;
      };

      config = {
        home = {
          stateVersion = lib.mkDefault "24.11";
          packages = [ config.monolisa.package ];
          sessionVariables.EDITOR = "nvim";
        };

        xdg.userDirs = {
          enable = true;
          createDirectories = true;
          desktop = null;
          templates = null;
          publicShare = null;
          music = null;
          videos = null;
          setSessionVariables = true;
        };

        fonts.fontconfig = {
          enable = true;
          defaultFonts.monospace = lib.mkDefault [ "MonoLisa Variable" ];
        };

        programs = {
          bat.enable = true;
          brightnessctl.enable = true;
          btop.enable = true;
          cryptsetup.enable = true;
          direnv.enable = true;
          eza.enable = true;
          fzf.enable = true;
          git.enable = true;
          gh.enable = true;
          gpg.enable = true;
          home-manager.enable = true;
          jq.enable = true;
          just_.enable = true;
          killall.enable = true;
          macchina.enable = true;
          magic-wormhole.enable = true;
          mat2.enable = true;
          nix-auth.enable = true;
          nix-index.enable = true;
          nvim.enable = true;
          p7zip.enable = true;
          pulsemixer.enable = true;
          qalculate.enable = true;
          ripgrep.enable = true;
          starship.enable = true;
          pay-respects.enable = true;
          wget.enable = true;
          xsel.enable = true;
          yazi.enable = true;
          zip.enable = true;
          zsh.enable = true;
        };

        services = {
          mpris-proxy.enable = true;
          udiskie.enable = true;
        };
      };
    };
}
