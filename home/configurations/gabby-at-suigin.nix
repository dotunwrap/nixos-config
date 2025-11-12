_: _:
{
  activeBundles = [
    "development"
    "dwm"
  ];

  themes = {
    enable = true;
    image = ../../assets/wallpapers/bay.jpeg;
    opacity = 0.8;
  };

  xresources.properties = {
    "Xft.dpi" = "150";
  };

  home.stateVersion = "24.11";
}
// import ./shared/gabby.nix
