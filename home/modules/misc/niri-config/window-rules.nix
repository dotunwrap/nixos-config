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
  }
]
