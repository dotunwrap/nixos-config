_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.waybar;
in
{
  config = lib.mkIf cfg.enable {
    stylix.targets.waybar.addCss = lib.mkDefault false;

    programs.waybar = {
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
          format-icons = {
            default = [
              "󰕿"
              "󰖀"
              "󰕾"
            ];
          };
          on-click = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
          on-click-right = "pavucontrol";
        };

        cpu = {
          format = "{usage}% ";
        };

        memory = {
          format = "{}% ";
        };

        tray = {
          icon-size = 16;
          spacing = 10;
        };

        clock = {
          format = "{:%d-%b-%a | %I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
      };

      # Non-floating bar: one continuous, opaque `window#waybar` background
      # spans the full width (no margins, no per-module pills/gaps), colored
      # via the `@baseXX` GTK custom properties Stylix defines (base16
      # slots, see themes/catppuccin/default.nix for the mapping) so it
      # stays dynamic across hosts/themes. mkAfter appends after Stylix's
      # target output (which defines those vars), layering on top rather
      # than replacing the stylesheet outright.
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
}
