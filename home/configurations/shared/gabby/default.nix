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

  programs = {
    bisq.enable = true;
    eigenwallet.enable = true;
    gajim.enable = true;
    git.settings.user = {
      name = "Gabby Simpson";
      email = "gabby@dotunwrap.dev";
    };
    trezor-suite.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      matchBlocks = {
        "*" = {
          forwardAgent = false;
          serverAliveInterval = 0;
          serverAliveCountMax = 3;
          compression = false;
          addKeysToAgent = "no";
          hashKnownHosts = false;
          userKnownHostsFile = "~/.ssh/known_hosts";
          controlMaster = "no";
          controlPath = "~/.ssh/master-%r@%n:%p";
          controlPersist = "no";
        };
        "github.com" = {
          hostname = "github.com";
          identityFile = "~/.ssh/github_ed25519";
          forwardAgent = true;
        };
      };
    };
    starship.prompt = "pure";
    zen-browser = lib.mkIf config.programs.zen-browser.enable (
      import ./zen {
        inherit
          firefox-addons
          system
          pkgs
          ;
      }
    );
  };

  stylix.targets.zen-browser.profileNames = lib.mkIf config.programs.zen-browser.enable [ "default" ];
}
