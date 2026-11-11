{ inputs, ... }:
let
  themes = import ./_themes.nix;
in
{
  den.aspects.nia = {
    # Formerly nixos/configurations/users/nia.nix -- lands on users.users.nia
    # on every host nia is declared on.
    user =
      { pkgs, ... }:
      {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "audio"
          "networkmanager"
          "dialout"
        ];
      };

    # Formerly home/configurations/shared/nia/default.nix -- cross-host, not
    # tied to either of nia's hosts (meiousei/suisei).
    homeManager =
      { config, pkgs, ... }:
      let
        inherit (pkgs.stdenv.hostPlatform) system;
      in
      {
        accounts = {
          calendar.basePath = ".local/share/calendars";
          contact.basePath = ".local/share/contacts";
        };

        # Her own MonoLisa variant, in place of the default (gabby's)
        # "MonoLisa Variable" -- feeds modules/defaults.nix's
        # `stylix.fonts.monospace.package = mkDefault config.monolisa.package`
        # automatically; only the display name needs its own override here.
        monolisa.package = inputs.monolisa.packages.${system}.nia;
        fonts.fontconfig.defaultFonts.monospace = [ "MonoLisa Nia" ];
        stylix.fonts.monospace.name = "MonoLisa Nia";

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

          # A chromium browser is required for betaflight to function properly.
          chromium = {
            enable = true;
            package = pkgs.ungoogled-chromium;
          };

          firefox = {
            enable = true;
            configPath = "${config.xdg.configHome}/mozilla/firefox";
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
              extensions.packages = with inputs.firefox-addons.packages.${system}; [
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

          qutebrowser.enable = false;
          zen-browser.enable = false;
        };

        nvim.package = inputs.niavim.packages.${system}.default;

        # Formerly home/modules/programs/winboat -- rootless podman as
        # winboat's container runtime; winboat checks for `podman compose`
        # with the podman-compose provider.
        services.podman.enable = true;
        home.packages = [
          pkgs.fldigi
          pkgs.sdrpp
          pkgs.gqrx
          pkgs.soapysdr
          pkgs.bottles
          pkgs.betaflight-configurator
          pkgs.winboat
          pkgs.podman-compose
        ];

        stylix.targets.firefox.profileNames = [ "default" ];
      };

    # Theme+wallpaper is her own choice, not her host's -- see
    # modules/users/gabby.nix for why this lives here instead of on the host.
    provides = {
      meiousei.homeManager = themes.catppuccin {
        image = ../../assets/wallpapers/anyb-girl.png;
      };
      suisei.homeManager = themes.everforest {
        image = ../../assets/wallpapers/bubbles.jpg;
        flavor = "hard";
      };
    };
  };
}
