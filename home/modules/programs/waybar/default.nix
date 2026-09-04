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
    stylix.targets.waybar = {
      addCss = lib.mkDefault true;
      enableLeftBackColors = lib.mkDefault true;
      enableCenterBackColors = lib.mkDefault true;
      enableRightBackColors = lib.mkDefault true;
    };

    programs.waybar = {
      systemd.enable = lib.mkDefault true;

      settings.mainBar = lib.mkDefault {
        layer = "top";
        position = "top";
        height = 32;
        margin-top = 0;
        margin-left = 0;
        margin-right = 0;
        spacing = 5;

        modules-left = [
          "niri/workspaces"
        ];
        modules-center = [
          "clock"
        ];
        modules-right = [
          "pulseaudio"
          "cpu"
          "memory"
          "battery"
          "tray"
        ];

        "niri/workspaces" = {
          format = "{icon}";
          format-icons = {
            default = "○";
            focused = "●";
          };
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
          format = "{:%a, %b %d | %I:%M %p}";
          tooltip-format = "<big>{:%Y %B}</big>\n<tt><small>{calendar}</small></tt>";
        };
      };
    };
  };
}
