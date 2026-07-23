{ lib }:

{
  gaps = lib.mkDefault 16;
  struts = {
    left = lib.mkDefault 64;
    right = lib.mkDefault 64;
  };
  empty-workspace-above-first = lib.mkDefault true;
  focus-ring = {
    enable = lib.mkDefault false;
  };
  border = {
    enable = lib.mkDefault true;
    width = lib.mkDefault 4;
  };
  shadow = {
    enable = lib.mkDefault true;
  };
  tab-indicator = {
    position = lib.mkDefault "top";
    gaps-between-tabs = lib.mkDefault 10;
  };
}
