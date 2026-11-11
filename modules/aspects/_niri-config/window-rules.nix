{ lib, ... }:
[
  {
    draw-border-with-background = lib.mkDefault false;
    geometry-corner-radius =
      let
        r = 8.0;
      in
      {
        top-right = lib.mkDefault r;
        top-left = lib.mkDefault r;
        bottom-right = lib.mkDefault r;
        bottom-left = lib.mkDefault r;
      };
    clip-to-geometry = lib.mkDefault true;
    opacity = 0.8;
  }
  {
    matches = [
      { is-active = true; }
    ];
    opacity = 0.9;
  }
  {
    matches = [
      { app-id = "^zen-twilight$"; }
      { app-id = "^firefox$"; }
      { app-id = "^freetube$"; }
      { app-id = "^Tor Browser$"; }
    ];
    opacity = 1.0;
  }
  {
    matches = [
      { app-id = "^signal$"; }
      { app-id = "^vesktop$"; }
    ];
    open-maximized = true;
  }
  {
    matches = [
      { app-id = "^org\\.wezfurlong\\.wezterm"; }
    ];
    default-window-height = {
      proportion = 1.0;
    };
  }
]
