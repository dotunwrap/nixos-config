{ den, ... }:
{
  den.aspects.nia = {
    # primary-user supplies isNormalUser + wheel/networkmanager; user-shell
    # "zsh" (den.default.includes, modules/defaults.nix) supplies the shell
    # -- only the extra, not-shared-by-every-user groups are left to say
    # here. insecure scopes nwjs permission to just her (betaflight-
    # configurator's dependency), rather than the blanket default every
    # other user also used to get.
    # Theme+wallpaper is her own choice, not her host's -- see
    # modules/users/gabby/default.nix for why this lives here instead of on
    # the host. Theme and wallpaper are independent batteries
    # (modules/aspects/batteries/{everforest,catppuccin,wallpaper}.nix).
    includes = [
      den.batteries.primary-user
      (den.batteries.insecure [ "nwjs-0.102.1" ])
      (den.batteries.catppuccin { hosts = [ "meiousei" ]; })
      (den.batteries.everforest {
        hosts = [ "suisei" ];
        flavor = "hard";
      })
      (den.batteries.wallpaper {
        meiousei = ../../assets/wallpapers/anyb-girl.png;
        suisei = ../../assets/wallpapers/bubbles.jpg;
      })
    ];

    # Formerly nixos/configurations/users/nia.nix -- lands on users.users.nia
    # on every host nia is declared on.
    user = {
      extraGroups = [
        "audio"
        "dialout"
      ];
    };

    # Formerly home/configurations/shared/nia/default.nix -- cross-host, not
    # tied to either of nia's hosts (meiousei/suisei).
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

        # Her own MonoLisa variant, in place of the default (gabby's)
        # "MonoLisa Variable" -- feeds modules/defaults.nix's
        # `stylix.fonts.monospace.package = mkDefault config.monolisa.package`
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

  };
}
