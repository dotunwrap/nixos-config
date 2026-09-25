{
  firefox-addons,
  stylix,
  niavim,
  monolisa,
  ...
}:
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

  bundles.base.monolisaVersion = monolisa.packages.${system}.nia;
  fonts.fontconfig.defaultFonts.monospace = [ "MonoLisa Nia" ];
  stylix.fonts.monospace = {
    package = monolisa.packages.${system}.nia;
    name = "MonoLisa Nia";
  };

  programs = {
    git.settings.user = {
      name = "Nia Williams";
      email = "niayoshe@gmail.com";
    };
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
    betaflight-configurator.enable = true;
    chromium = {
      # A chromium browser is required for betaflight to function properly
      enable = true;
      package = pkgs.ungoogled-chromium;
    };
    firefox = {
      enable = true;
      profiles.default = {
        settings = {
          "browser.aboutConfig.showWarning" = false;
          "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "extensions.update.autoUpdateDefault" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "signon.rememberSignons" = false;
        };
        extensions.packages = with firefox-addons.packages.${system}; [
          bitwarden
          ublock-origin
          reddit-enhancement-suite
        ];
      };
    };
    zsh.shellAliases = {
      cl = "clang";
      clpp = "clang++";
    };

    starship.prompt = "pure";

    nvim.package = niavim.packages.${system}.default;

    qutebrowser.enable = false;
    zen-browser.enable = false;
    fldigi.enable = true;
    sdrpp.enable = true;
    gqrx.enable = true;
    soapysdr.enable = true;
    winboat.enable = true;
    bottles-unwrapped.enable = true;
  };

  stylix.targets.firefox.profileNames = [ "default" ];
}
