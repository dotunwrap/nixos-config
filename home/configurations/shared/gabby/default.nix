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
    feather-wallet.enable = true;
    gajim.enable = true;
    git.settings.user = {
      name = "Gabby Simpson";
      email = "gabby@dotunwrap.dev";
    };
    monero-cli.enable = true;
    trezor-suite.enable = true;
    ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "*" = {
          ForwardAgent = false;
          ServerAliveInterval = 0;
          ServerAliveCountMax = 3;
          Compression = false;
          AddKeysToAgent = "no";
          HashKnownHosts = false;
          UserKnownHostsFile = "~/.ssh/known_hosts";
          ControlMaster = "no";
          ControlPath = "~/.ssh/master-%r@%n:%p";
          ControlPersist = "no";
        };
        "github.com" = {
          HostName = "github.com";
          IdentityFile = "~/.ssh/github_ed25519";
          ForwardAgent = true;
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
