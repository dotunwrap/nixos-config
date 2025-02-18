{ pkgs, ... }:

{
  home.packages = with pkgs; [
    lxsession
  ];
}
