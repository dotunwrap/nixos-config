{
  firefox-addons,
  stylix,
  niavim,
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

  programs = {
    git.settings.user = {
      name = "Nia Williams";
      email = "niayoshe@gmail.com";
    };
    ssh = {
      enable = true;
      matchBlocks = {
        "github.com" = {
          hostname = "github.com";
          identityFile = "~/.ssh/github_ed25519";
          forwardAgent = true;
        };
      };
    };
    firefox = {
      enable = true;
      profiles.nia = {
        settings = {
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "services.sync.prefs.sync.browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.urlbar.suggest.quicksuggest.sponsored" = false;
          "browser.newtabpage.activity-stream.system.showSponsored" = false;
          "browser.newtabpage.activity-stream.showSponsoredTopSites" = false;
          "browser.newtabpage.activity-stream.showSponsoredCheckboxes" = false;
          "browser.newtabpage.activity-stream.showSponsored" = false;
          "browser.newtabpage.activity-stream.discoverystream.enabled" = false;
          "browser.newtabpage.activity-stream.feeds.section.topstories" = false;
        };
        extensions.packages = with firefox-addons.packages.${system}; [
          bitwarden
          ublock-origin
          reddit-enhancement-suite
        ];
      };
    };
    programming = {
      c.enable = false;
      cpp.enable = true;
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
    arduino-cli.enable = true;
  };

  stylix.targets.firefox.profileNames = [ "nia" ];
}
