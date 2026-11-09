_:
{ pkgs, ... }:
{
  activeBundles = [
    "base"
    "development"
    # TODO: Build and add a "server" bundle.
  ];

  networking = {
    hostName = "europa";
    networkmanager.enable = true;
  };

  services.libinput = {
    enable = true;
    touchpad = {
      tapping = true;
      naturalScrolling = true;
    };
  };

  time.timeZone = "America/New_York";

  i18n = {
    defaultLocale = "en_US.UTF-8";
  };

  # TODO: Add some sysadmin user for servers to ingest
  # users.users = ...
}
