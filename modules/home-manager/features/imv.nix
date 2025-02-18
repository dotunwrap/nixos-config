{ pkgs, ... }:

{
  home.packages = with pkgs; [
    imv
  ];

  xdg.mimeApps.defaultApplications = {
    "image/*" = [ "imv.desktop" ];
  };
}
