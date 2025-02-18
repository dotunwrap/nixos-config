{ pkgs, ... }:

{
  home.packages = with pkgs; [
    mpv
  ];

  xdg.mimeApps.defaultApplications = {
    "video/png" = [ "mpv.desktop" ];
    "video/jpg" = [ "mpv.desktop" ];
    "video/*" = [ "mpv.desktop" ];
  };
}
