{ lib, ... }:

{
  gaps = lib.mkDefault 12;
  focus-ring = {
    enable = lib.mkDefault false;
  };
  border = {
    enable = lib.mkDefault true;
    width = lib.mkDefault 2;
  };
  shadow = {
    enable = lib.mkDefault true;
    softness = lib.mkDefault 30;
    spread = lib.mkDefault 4;
    offset = {
      x = lib.mkDefault 0;
      y = lib.mkDefault 0;
    };
  };
}
