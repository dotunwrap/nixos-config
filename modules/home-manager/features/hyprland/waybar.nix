{ ... }: let
  icons = {
    default = "";
    backlight = ["" "" "" "" "" "" "" "" ""];
    battery = ["" "" "" "" "" "" "" "" "" "" "" ""];
    pulseaudio = ["" "" ""];
  };
in {
  programs.waybar = {
    enable = true;

    settings = {
      # Position and layer of Waybar
      position = "top";
      layer = "top";

      # Modules arrangement
      "modules-left" = [ "wlr/workspaces" ];
      "modules-center" = [ "custom/music" ];
      "modules-right" = [ "pulseaudio" "backlight" "battery" "clock" "tray" "custom/lock" "custom/power" ];

      # Workspaces module settings
      "wlr/workspaces" = {
        disable-scroll = true;
        "sort-by-name" = true;
        format = " {icon} ";
        "format-icons" = {
          default = icons.default;
        };
      };

      # Tray settings
      tray = {
        "icon-size" = 21;
        spacing = 10;
      };

      # Music module settings
      "custom/music" = {
        format = "  {}";
        escape = true;
        interval = 5;
        tooltip = false;
        exec = "playerctl metadata --format='{{ title }}'";
        "on-click" = "playerctl play-pause";
        "max-length" = 50;
      };

      # Clock settings
      clock = {
        timezone = "Asia/Dubai";
        "tooltip-format" = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        "format-alt" = " {:%d/%m/%Y}";
        format = " {:%H:%M}";
      };

      # Backlight settings
      backlight = {
        device = "intel_backlight";
        format = "{icon}";
        "format-icons" = icons.backlight;
      };

      # Battery settings
      battery = {
        states = {
          warning = 30;
          critical = 15;
        };
        format = "{icon}";
        "format-charging" = "";
        "format-plugged" = "";
        "format-alt" = "{icon}";
        "format-icons" = icons.battery;
      };

      # Pulseaudio settings
      pulseaudio = {
        format = "{icon} {volume}%";
        "format-muted" = "";
        "format-icons" = icons.pulseaudio;
        "on-click" = "pavucontrol";
      };

      # Lock screen module settings
      "custom/lock" = {
        tooltip = false;
        "on-click" = "sh -c '(sleep 0.5s; swaylock --grace 0)' & disown";
        format = "";
      };

      # Power module settings
      "custom/power" = {
        tooltip = false;
        "on-click" = "wlogout &";
        format = "襤";
      };
    };

    style = ''
      * {
        font-family: FantasqueSansMono Nerd Font;
        font-size: 17px;
        min-height: 0;
      }
        
      #waybar {
        background: transparent;
        color: @text;
        margin: 5px 5px;
      }
       
      #workspaces {
        border-radius: 1rem;
        margin: 5px;
        background-color: @surface0;
        margin-left: 1rem;
      }
       
      #workspaces button {
        color: @lavender;
        border-radius: 1rem;
        padding: 0.4rem;
      }
       
      #workspaces button.active {
        color: @sky;
        border-radius: 1rem;
      }
       
      #workspaces button:hover {
        color: @sapphire;
        border-radius: 1rem;
      }
       
      #custom-music,
      #tray,
      #backlight,
      #clock,
      #battery,
      #pulseaudio,
      #custom-lock,
      #custom-power {
        background-color: @surface0;
        padding: 0.5rem 1rem;
        margin: 5px 0;
      }
       
      #clock {
        color: @blue;
        border-radius: 0px 1rem 1rem 0px;
        margin-right: 1rem;
      }
       
      #battery {
        color: @green;
      }
       
      #battery.charging {
        color: @green;
      }
       
      #battery.warning:not(.charging) {
        color: @red;
      }
       
      #backlight {
        color: @yellow;
      }
       
      #backlight, #battery {
          border-radius: 0;
      }
       
      #pulseaudio {
        color: @maroon;
        border-radius: 1rem 0px 0px 1rem;
        margin-left: 1rem;
      }
       
      #custom-music {
        color: @mauve;
        border-radius: 1rem;
      }
       
      #custom-lock {
          border-radius: 1rem 0px 0px 1rem;
          color: @lavender;
      }
       
      #custom-power {
          margin-right: 1rem;
          border-radius: 0px 1rem 1rem 0px;
          color: @red;
      }
       
      #tray {
        margin-right: 1rem;
        border-radius: 1rem;
      }
    '';
  };

  wayland.windowManager.hyprland.settings.exec-once = "waybar";
}
