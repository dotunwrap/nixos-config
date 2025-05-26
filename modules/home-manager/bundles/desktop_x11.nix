{ lib, ... }:

{
  myUser = {
    bspwm.enable = lib.mkDefault true;
    sxhkd.enable = lib.mkDefault true;
  };
}
