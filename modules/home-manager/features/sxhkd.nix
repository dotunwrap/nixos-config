_:

{
  services.sxhkd = {
    enable = true;
    keybindings = {
      # BSPWM management
      # restart and quit BSPWM
      "super + alt + {q,r}" = "bspc {quit,wm -r}";
      # close and kill
      "super + {_,shift +} q" = "bspc node -{c,k}";
      # alternate between the tiled and monocle layout
      "super + m" = "bspc desktop -l next";
      # send the newest marked node to the newest preselected node
      "super + y" = "bspc node newest.marked.local -n newest.!automatic.local";
      # swap the current node and the biggest node
      "super + g" = "bspc node -s biggest";
      # set the window state
      "super + {t,shift + t,s,f}" = "bspc node -t {tiled,pseudo_tiled,floating,fullscreen}";
      # set the node flags
      "super + ctrl + {m,x,y,z}" = "bspc node -g {marked,locked,sticky,private}";

      # SXHKD management
      # reload the SXHKD daemon
      "super + ctrl + Escape" = "pkill -USR1 -x sxhkd";

      # Runner
      "super + {_,shift +} space" = "rofi -show {drun,run}";
      "alt + Tab" = "rofi -show window";

      # Useful program shortcuts
      "super + Return" = "alacritty";
      "super + shift + Return" = "brave";
    };
  };
}
