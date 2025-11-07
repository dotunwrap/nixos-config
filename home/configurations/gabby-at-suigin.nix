_: _: {
  activeBundles = [
    "development"
    "dwm"
  ];

  themes = {
    enable = true;
    image = ../../assets/wallpapers/bay.jpeg;
    opacity = 0.8;
  };

  accounts = {
    calendar.basePath = ".local/share/calendars";
    contact.basePath = ".local/share/contacts";
  };

  programs.git.settings.user = {
    name = "Gabby Simpson";
    email = "gabby@dotunwrap.dev";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/github_ed25519";
      };
    };
  };

  home.stateVersion = "24.11";
}
