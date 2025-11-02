_: _: {
  activeBundles = [
    "development"
    "dwm"
  ];

  accounts = {
    calendar.basePath = ".local/share/calendars";
    contact.basePath = ".local/share/contacts";
  };

  programs.git.settings.user = {
    name = "Gabby Simpson";
    email = "gabby@dotunwrap.dev";
  };

  programs.ssh.matchBlocks = {
    github = {
      hostname = "github.com";
      identityFile = "~/.ssh/github_ed25519";
    };
  };

  home.stateVersion = "24.11";
}
