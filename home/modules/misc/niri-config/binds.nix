{ lib }:
{
  # General binds
  "Mod+Q".action.close-window = [ ];
  "Mod+Space".action.spawn = [
    "vicinae"
    "open"
  ];
  "Mod+Shift+S".action.screenshot = [ ];
  "Print".action.screenshot-screen = [ ];
  "Mod+Print".action.screenshot-window = [ ];
}
// {
  # Program shortcuts
  "Mod+Return".action.spawn = "wezterm";
  "Mod+Shift+Return".action.spawn = "zen-twilight";
}
// {
  # FN row media controls
  "XF86AudioRaiseVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1+";
  "XF86AudioLowerVolume".action.spawn-sh = "wpctl set-volume @DEFAULT_AUDIO_SINK@ 0.1-";
  "XF86AudioMute".action.spawn-sh = "wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle";
  "XF86AudioNext".action.spawn-sh = "playerctl next";
  "XF86AudioPrev".action.spawn-sh = "playerctl previous";
  "XF86AudioPlay".action.spawn-sh = "playerctl play-pause";
  "XF86MonBrightnessUp".action.spawn-sh = "brightnessctl set 10%+";
  "XF86MonBrightnessDown".action.spawn-sh = "brightnessctl set 10%-";
}
