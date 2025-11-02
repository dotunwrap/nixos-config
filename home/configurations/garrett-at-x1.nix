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
    name = "Garrett Simpson";
    email = "garrett@dotunwrap.dev";
  };

  home.stateVersion = "24.11";
}
