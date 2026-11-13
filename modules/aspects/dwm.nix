{ den, ... }:
{
  flake-file.inputs.suckless = {
    url = "github:dotunwrap/suckless-nix";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
    };
  };

  den.aspects.dwm = {
    includes = [ den.aspects.desktop ];

    nixos =
      { pkgs, inputs', ... }:
      {
        fonts.packages = with pkgs; [
          corefonts

          noto-fonts
          noto-fonts-cjk-sans
          noto-fonts-color-emoji

          font-awesome

          garamond-libre

          nerd-fonts.jetbrains-mono
          nerd-fonts.fira-code
          nerd-fonts.symbols-only
        ];

        services.xserver = {
          enable = true;
          windowManager.dwm = {
            enable = true;
            package = inputs'.suckless.packages.dwm;
            extraSessionCommands = ''
              dwmblocks &
            '';
          };
        };
        environment.systemPackages = [ inputs'.suckless.packages.dwmblocks ];

        services.displayManager.defaultSession = "none+dwm";

        systemd.user.services.polkit-gnome-authentication-agent-1 = {
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

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [ xdg-desktop-portal-gtk ];
          config.common.default = "gtk";
        };
      };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        xsession.enable = true;
        xdg.userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

        # NOTE: formerly dmenu/lxsession/st's own custom modules -- none are
        # native Home Manager options, each was just
        # `home.packages = [ <package> ];` behind an enable flag. (feh's own
        # custom module had an empty body -- enabling it currently does
        # nothing, so it's dropped rather than ported as a no-op.)
        home.packages = [
          pkgs.dmenu
          pkgs.lxsession
          pkgs.st
        ];

        programs = {
          spotify-player.enable = lib.mkDefault true;

          nushell = {
            enable = lib.mkDefault true;
            shellAliases = {
              ols = "ls";
              oll = "ls -la";
            };
          };

          obs-studio.plugins = with pkgs.obs-studio-plugins; [ droidcam-obs ];

          qutebrowser = {
            enable = lib.mkDefault true;
            greasemonkey = [
              (pkgs.fetchurl {
                url = "https://raw.githubusercontent.com/qutebrowser/qutebrowser/refs/heads/main/misc/userscripts/qute-bitwarden";
                sha256 = "sha256-oHjwIefAsjcDzVH1h+ykwFn+C0u+ALpFI2q6D6f0SiQ=";
              })
            ];
            keyBindings = {
              normal = {
                "[b" = "tab-prev";
                "]b" = "tab-next";
                "St" = lib.mkMerge [
                  "config-cycle tabs.show never always"
                  "config-cycle statusbar.show never always"
                  "config-cycle scrolling.bar never always"
                ];
              };
            };
          };
        };

        xdg.mimeApps = {
          enable = true;
          defaultApplications = {
            "x-scheme-handler/http" = "org.qutebrowser.qutebrowser.desktop";
            "x-scheme-handler/https" = "org.qutebrowser.qutebrowser.desktop";
          };
        };

        services = {
          dunst.enable = true;
          flameshot.enable = true;
          picom = {
            enable = true;
            backend = "glx";
            shadow = true;
            inactiveOpacity = 0.8;
            activeOpacity = 0.9;
            opacityRules = [
              "100:class_g = 'firefox'"
              "100:class_g = 'qutebrowser'"
              "100:fullscreen"
            ];
            settings.blur = {
              method = "dual_kawase";
              size = 10;
              deviation = 5.0;
            };
          };
        };
      };
  };
}
