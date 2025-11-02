_: _:

{
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

  home.stateVersion = "25.11";
}
