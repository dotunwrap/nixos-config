{ inputs, den, ... }:
{
  den.aspects.niri = {
    includes = [ den.aspects.desktop-shared ];

    nixos =
      { pkgs, ... }:
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

        programs.niri.enable = true;
        programs.vicinae.input-server.enable = true;

        services.displayManager.defaultSession = "niri";
        services.gnome.gnome-keyring.enable = true;

        xdg.portal = {
          enable = true;
          extraPortals = with pkgs; [
            xdg-desktop-portal-gtk
            xdg-desktop-portal-gnome
          ];
          config.niri = {
            default = [ "gtk" ];
            "org.freedesktop.impl.portal.ScreenCast" = [ "gnome" ];
            "org.freedesktop.impl.portal.Screenshot" = [ "gnome" ];
          };
        };

        security.soteria.enable = true;
      };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
        # vicinae deliberately doesn't follow our nixpkgs (see flake.nix), so
        # its glibc is older than the system's. The host Mesa in
        # /run/opengl-driver then fails to load inside its process (GLIBC_x.y
        # not found) and both EGL and Vulkan break. Use a Mesa from vicinae's
        # own pin so the libc versions match.
        # TODO: This should be removed when the issue #2040 is resolved
        vicinaeMesa = inputs.vicinae.inputs.nixpkgs.legacyPackages.${system}.mesa;
        vicinaeIcds =
          lib.concatMapStringsSep ":" (n: "${vicinaeMesa}/share/vulkan/icd.d/${n}_icd.x86_64.json")
            [
              "intel"
              "radeon"
              "nouveau"
            ];

        setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
          until ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do sleep 0.2; done
          exec ${pkgs.awww}/bin/awww img ${config.stylix.image}
        '';
      in
      {
        xdg = {
          userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

          mimeApps = {
            enable = true;
            defaultApplications."application/pdf" = lib.mkDefault "zen-twilight.desktop";
          };

          # Formerly home/modules/services/swayosd's own CSS, layered on HM's
          # native services.swayosd.
          configFile."swayosd/style.css".text =
            let
              colors = config.lib.stylix.colors.withHashtag;
            in
            lib.mkDefault ''
              window#osd {
                border-radius: 8px;
                border: 1px solid ${colors.base02};
                background: alpha(${colors.base00}, 0.94);
                padding: 4px;
              }

              window#osd #container {
                margin: 16px;
              }

              window#osd image,
              window#osd label {
                color: ${colors.base05};
              }

              window#osd progressbar:disabled,
              window#osd image:disabled {
                opacity: 0.5;
              }

              window#osd progressbar {
                min-height: 6px;
                border-radius: 0;
                background: transparent;
                border: none;
              }

              window#osd trough {
                min-height: 6px;
                border-radius: 0;
                border: none;
                background: ${colors.base03};
              }

              window#osd progress {
                min-height: 6px;
                border-radius: 0;
                border: none;
                # Formerly `colors.mauve` -- not a real stylix color key, but
                # this matches the base16 slot "mauve" maps to via the
                # catppuccin accent override (modules/hosts/kaiousei.nix,
                # modules/hosts/meiousei.nix).
                background: ${colors.base0E};
              }
            '';
        };

        home = {
          # Formerly imagemagick/proton-authenticator/protonmail-desktop/vlc/
          # wayland-utils/wl-clipboard's own custom modules -- none are native
          # Home Manager options, each was just `home.packages = [ <package> ];`
          # behind an enable flag.
          packages = [
            pkgs.imagemagick
            pkgs.proton-authenticator
            pkgs.protonmail-desktop
            pkgs.vlc
            pkgs.wayland-utils
            pkgs.wl-clipboard
            pkgs.xwayland-satellite
          ];

          activation = {
            restartVicinaeServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              run systemctl --user restart vicinae.service || true
            '';
            reloadNiri = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
              if [ -n "''${NIRI_SOCKET:-}" ]; then
                run ${config.programs.niri.package}/bin/niri msg action load-config-file || true
              fi
            '';
          };
        };

        programs = {
          element-desktop.enable = lib.mkDefault true;
          freetube.enable = lib.mkDefault true;
          freetube.settings = {
            checkForUpdates = lib.mkDefault false;
            defaultQuality = lib.mkDefault "1080";
            hideUpcomingPremieres = lib.mkDefault true;
            hideChannelShorts = lib.mkDefault true;
            useSponsorBlock = lib.mkDefault true;
            sponsorBlockInteraction.skip = lib.mkDefault "doNothing";
          };

          zen-browser = {
            enable = lib.mkDefault true;
            setAsDefaultBrowser = lib.mkDefault true;
          };

          vicinae = {
            enable = lib.mkDefault true;
            systemd = {
              enable = lib.mkDefault true;
              autoStart = lib.mkDefault true;
              environment = {
                USE_LAYER_SHELL = lib.mkDefault 1;
                QSG_RHI_BACKEND = lib.mkDefault "vulkan";
                VK_DRIVER_FILES = lib.mkDefault vicinaeIcds;
              };
            };
            settings = {
              close_on_focus_loss = lib.mkDefault true;
              consider_preedit = lib.mkDefault true;
              pop_to_root_on_close = lib.mkDefault true;
              basic_usage_statistics = false;
              providers = {
                "@dagimg-dot/vicinae-extension-wifi-commander-0" = {
                  preferences.network-cli-tool = "nmcli";
                };
              };
            };
            extensions =
              with inputs.vicinae-extensions.packages.${system};
              lib.mkDefault [
                # NOTE: bluetooth and systemd are currently not building for
                # nix-unstable
                # https://github.com/vicinaehq/extensions/blob/ca74eede9a778a9373c8f5fd221b0a5026dcd1ef/flake.nix#L65
                # bluetooth
                # systemd
                nix
                wifi-commander
                pulseaudio
                niri
                it-tools
              ];
          };

          waybar = {
            enable = lib.mkDefault true;
            systemd.enable = lib.mkDefault true;

            settings.mainBar = lib.mkDefault {
              layer = "top";
              position = "top";
              height = 34;
              margin-top = 0;
              margin-left = 0;
              margin-right = 0;
              spacing = 5;

              modules-left = [
                "niri/workspaces"
                "niri/window"
              ];
              modules-center = [ ];
              modules-right = [
                "pulseaudio"
                "cpu"
                "memory"
                "battery"
                "tray"
                "clock"
              ];

              "niri/workspaces" = {
                format = "{icon}";
                format-icons = {
                  default = "○";
                  focused = "●";
                };
              };

              "niri/window" = {
                format = "{title}";
                max-length = 35;
              };

              battery = {
                states = {
                  warning = 30;
                  critical = 15;
                };
                format = "{capacity}% {icon}";
                format-charging = "{capacity}% 󱐋";
                format-full = "{capacity}% {icon}";
                format-icons = [
                  "󰂎"
                  "󰁺"
                  "󰁻"
                  "󰁼"
                  "󰁽"
                  "󰁾"
                  "󰁿"
                  "󰂀"
                  "󰂁"
                  "󰂂"
                  "󰁹"
                ];
                interval = 2;
              };

              pulseaudio = {
                format = "{volume}% {icon}";
                format-muted = "󰖁";
                format-icons.default = [
                  "󰕿"
                  "󰖀"
                  "󰕾"
                ];
                on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
                on-click-right = "pavucontrol";
              };

              cpu.format = "{usage}% ";
              memory.format = "{}% ";
              tray = {
                icon-size = 16;
                spacing = 10;
              };
              clock = {
                format = "{:%d-%b-%a | %I:%M %p}";
                tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
              };
            };

            # Non-floating bar: one continuous, opaque `window#waybar`
            # background spans the full width (no margins, no per-module
            # pills/gaps), colored via the `@baseXX` GTK custom properties
            # Stylix defines (base16 slots) so it stays dynamic across
            # hosts/themes. mkAfter appends after Stylix's target output
            # (which defines those vars), layering on top rather than
            # replacing the stylesheet outright.
            style = lib.mkAfter ''
              * {
                border: none;
                font-family: "JetBrainsMono Nerd Font", "Roboto", sans-serif;
                font-size: 13px;
              }

              window#waybar {
                background-color: @base00;
                color: @base05;
                border-radius: 0;
              }

              #workspaces,
              #window,
              #pulseaudio,
              #cpu,
              #memory,
              #battery,
              #tray,
              #clock {
                padding: 0 10px;
              }

              /* Battery color logic */
              #battery {
                color: @base08;
                /* Default (discharging) */
              }

              #battery.charging {
                color: @base0B;
              }

              #battery.full {
                color: @base0D;
              }

              #battery.warning:not(.charging) {
                color: @base09;
              }

              /* Other module colors */
              #workspaces button {
                padding: 0 6px;
                color: @base09;
              }

              #workspaces button.focused {
                color: @base0A;
              }

              #clock {
                color: @base0E;
              }

              #pulseaudio {
                color: @base0D;
              }

              #pulseaudio:hover {
                background-color: @base0D;
                color: @base00;
              }

              #cpu {
                color: @base0C;
              }
            '';
          };
        };

        stylix.targets.waybar.addCss = lib.mkDefault false;

        programs.niri.settings =
          let
            importDefaultSettings = f: import f { inherit lib pkgs config; };
          in
          {
            input = importDefaultSettings ./_niri-config/input.nix;
            binds = importDefaultSettings ./_niri-config/binds.nix;
            layout = importDefaultSettings ./_niri-config/layout.nix;
            window-rules = importDefaultSettings ./_niri-config/window-rules.nix;

            clipboard.disable-primary = lib.mkDefault true;
            prefer-no-csd = lib.mkDefault true;
            overview.zoom = lib.mkDefault 0.5;

            environment = {
              NIX_OZONE_WL = lib.mkDefault "1";
              MOZ_ENABLE_WAYLAND = lib.mkDefault "1";
              ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "1";
              QT_QPA_PLATFORMTHEME = lib.mkDefault "gtk3";
              QT_STYLE_OVERRIDE = lib.mkDefault "adwaita-dark";
            };

            spawn-at-startup = [ { command = [ "${setWallpaper}" ]; } ];
          };

        services = {
          mako.enable = lib.mkDefault true;
          playerctld.enable = lib.mkDefault true;
          awww.enable = lib.mkDefault true;
          swayidle = {
            enable = true;
            events.before-sleep = "";
          };

          # Formerly home/modules/services/swayosd (its own custom module,
          # layered on HM's native services.swayosd).
          swayosd.enable = true;
        };
      };
  };
}
