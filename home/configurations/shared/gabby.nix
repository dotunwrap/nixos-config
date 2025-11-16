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

  programs.starship.prompt = "pure";

  programs.zen-browser.profiles.gabby = lib.mkIf config.programs.zen-browser.enable {
    extensions.packages = with firefox-addons.packages.${system}; [
      bitwarden
      ublock-origin
      darkreader
    ];
  };

  stylix.targets.zen-browser.profileNames = lib.mkIf config.programs.zen-browser.enable [ "gabby" ];
}
