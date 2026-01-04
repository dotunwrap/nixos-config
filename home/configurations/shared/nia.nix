{ firefox-addons, stylix, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  accounts = {
    calendar.basePath = ".local/share/calendars";
    contact.basePath = ".local/share/contacts";
  };

  programs.git.settings.user = {
    name = "Nia Williams";
    email = "niayoshe@gmail.com";
  };

  programs.ssh = {
    enable = true;
    matchBlocks = {
      "github.com" = {
        hostname = "github.com";
        identityFile = "~/.ssh/github_ed25519";
        forwardAgent = true;
      };
    };
  };

  programs.starship.prompt = "pure";

  programs.qutebrowser.enable = false;
  programs.firefox = {
    enable = true;
  };
}
