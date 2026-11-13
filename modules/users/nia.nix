{ den, ... }:
{
  flake-file.inputs.niavim = {
    url = "github:nyoshe/niavim";
    inputs = {
      nixpkgs.follows = "nixpkgs";
      flake-parts.follows = "flake-parts";
      nixvim.follows = "nixvim";
      systems.follows = "systems-future";
    };
  };

  den.aspects.nia = {
    # NOTE: insecure scopes the nwjs permission (betaflight-configurator's
    # dependency) to just her, not the blanket default every user used to get.
    includes = [
      den.batteries.primary-user
      (den.batteries.insecure [ "nwjs-0.102.1" ])
      (den.batteries.theme {
        hosts = [ "meiousei" ];
        scheme = "catppuccin-mocha";
      })
      (den.batteries.theme {
        hosts = [ "suisei" ];
        scheme = "everforest-dark-hard";
      })
      (den.batteries.wallpaper {
        host = "meiousei";
        path = ../../assets/wallpapers/anyb-girl.png;
      })
      (den.batteries.wallpaper {
        host = "suisei";
        path = ../../assets/wallpapers/bubbles.jpg;
      })
    ];

    user = {
      extraGroups = [
        "audio"
        "dialout"
      ];
    };

    homeManager =
      {
        config,
        pkgs,
        inputs',
        ...
      }:
      {
        accounts = {
          calendar.basePath = ".local/share/calendars";
          contact.basePath = ".local/share/contacts";
        };

        # NOTE: feeds modules/defaults.nix's `mkDefault config.monolisa.package`
        # automatically; only the display name needs its own override here.
        monolisa.package = inputs'.monolisa.packages.nia;
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

          # NOTE: a chromium browser is required for betaflight to function properly.
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
              extensions.packages = with inputs'.firefox-addons.packages; [
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

        nvim.package = inputs'.niavim.packages.default;

        # NOTE: rootless podman as winboat's container runtime; winboat checks
        # for `podman compose` with the podman-compose provider.
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

  };
}
