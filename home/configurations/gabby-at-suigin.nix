_: _: {
  activeBundles = [
    "development"
    "dwm"
  ];

  home.file.".background-image".source = ../../assets/wallpapers/gruvbox_pixels.png;

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
