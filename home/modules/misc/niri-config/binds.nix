{
  lib,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.niri.actions)
    spawn
    spawn-sh
    close-window
    focus-column-left
    focus-column-right
    focus-window-down
    focus-window-up
    move-column-left
    move-column-right
    move-window-down
    move-window-up
    move-column-to-workspace-down
    move-column-to-workspace-up
    focus-workspace
    focus-workspace-down
    focus-workspace-up
    set-column-width
    set-window-height
    switch-preset-column-width
    maximize-column
    fullscreen-window
    ;

  workspaceBinds = lib.listToAttrs (
    lib.map (n: {
      name = "Mod+${toString n}";
      value.action = focus-workspace n;
    }) (lib.range 1 9)
  );
in
{
  # General binds
  "Mod+Q".action = close-window;

  "Mod+H".action = focus-column-left;
  "Mod+L".action = focus-column-right;
  "Mod+J".action = focus-window-down;
  "Mod+K".action = focus-window-up;

  "Mod+Shift+H".action = move-column-left;
  "Mod+Shift+L".action = move-column-right;
  "Mod+Shift+J".action = move-window-down;
  "Mod+Shift+K".action = move-window-up;

  "Mod+Ctrl+J".action = focus-workspace-down;
  "Mod+Ctrl+K".action = focus-workspace-up;

  "Mod+Shift+Ctrl+J".action = move-column-to-workspace-down;
  "Mod+Shift+Ctrl+K".action = move-column-to-workspace-up;

  "Mod+Minus".action = set-column-width "-10%";
  "Mod+Equal".action = set-column-width "+10%";
  "Mod+Shift+Minus".action = set-window-height "-10%";
  "Mod+Shift+Equal".action = set-window-height "+10%";
  "Mod+R".action = switch-preset-column-width;
  "Mod+F".action = maximize-column;
  "Mod+Shift+F".action = fullscreen-window;

  "Mod+Shift+S".action.screenshot = [ ];
}
// {
  # Program shortcuts
  "Mod+Return".action = spawn "wezterm";
  "Mod+Shift+Return".action = spawn "zen-twilight";
  "Mod+Space".action = spawn-sh "vicinae open";
  "Mod+Shift+E".action = spawn-sh "vicinae 'vicinae://launch/power'";
  "Mod+Period".action = spawn-sh "vicinae 'vicinae://launch/core/search-emojis'";
}
// {
  # FN row media controls
  "XF86AudioRaiseVolume".action = spawn-sh "swayosd-client --output-volume raise";
  "XF86AudioLowerVolume".action = spawn-sh "swayosd-client --output-volume lower";
  "XF86AudioMute".action = spawn-sh "swayosd-client --output-volume mute-toggle";
  "XF86AudioNext".action = spawn-sh "swayosd-client --playerctl next";
  "XF86AudioPrev".action = spawn-sh "swayosd-client --playerctl previous";
  "XF86AudioPlay".action = spawn-sh "swayosd-client --playerctl play-pause";
  "XF86MonBrightnessUp".action = spawn-sh "swayosd-client --brightness raise";
  "XF86MonBrightnessDown".action = spawn-sh "swayosd-client --brightness lower";
}
// workspaceBinds
