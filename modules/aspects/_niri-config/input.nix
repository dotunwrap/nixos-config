{ lib, ... }:

{
  keyboard = {
    xkb = {
      layout = lib.mkDefault "us";
    };
  };
  mouse = { };
  touchpad = {
    tap = lib.mkDefault false;
    dwt = lib.mkDefault true;
    natural-scroll = lib.mkDefault true;
    click-method = lib.mkDefault "clickfinger";
  };
}
