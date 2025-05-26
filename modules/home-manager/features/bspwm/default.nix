{ pkgs, ... }:

{
  xsession.windowManager.bspwm = {
    enable = true;
    settings = {
      border_width = 2;
      window_gap = 6;
      split_ratio = 0.50;
      borderless_monocle = false;
      gapless_monocle = false;
      focus_follows_pointer = true;
      ignore_ewmh_focus = false;
      pointer_motion_interval = 5;
      pointer_modifier = "mod4";
      pointer_action1 = "move";
      pointer_action2 = "resize_side";
      pointer_action3 = "resize_corner";
    };
  };
}
