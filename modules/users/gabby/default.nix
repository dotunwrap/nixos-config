{ den, ... }:
{
  den.aspects.gabby = {
    # Theme/wallpaper is her own choice, not her host's -- set per host here
    # rather than the host deciding it for whoever's logged in.
    includes = [
      den.batteries.primary-user
      (den.batteries.theme {
        hosts = [ "chikyuu" ];
        scheme = "everforest-dark-medium";
      })
      (den.batteries.theme {
        hosts = [
          "kaiousei"
          "meiousei"
        ];
        scheme = "catppuccin-mocha";
      })
      (den.batteries.wallpaper {
        host = "chikyuu";
        path = ../../../assets/wallpapers/stephen_njoto.png;
      })
      (den.batteries.wallpaper {
        host = "kaiousei";
        path = ../../../assets/wallpapers/anyb-girl.png;
      })
      (den.batteries.wallpaper {
        host = "meiousei";
        path = ../../../assets/wallpapers/anyb-girl.png;
      })
    ];

    user = {
      extraGroups = [ "audio" ];
    };

    homeManager =
      {
        config,
        lib,
        pkgs,
        inputs',
        ...
      }:
      {
        accounts = {
          calendar.basePath = ".local/share/calendars";
          contact.basePath = ".local/share/contacts";
        };

        home.packages = [
          pkgs.bisq2
          pkgs.eigenwallet
          pkgs.feather
          pkgs.gajim
          pkgs.monero-cli
          pkgs.trezor-suite
          pkgs.python312Packages.trezor
          pkgs.vial
        ];

        programs = {
          git.settings.user = {
            name = "Gabby Simpson";
            email = "gabby@dotunwrap.dev";
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

          zen-browser = lib.mkIf config.programs.zen-browser.enable (
            import ./_zen {
              firefoxAddonPackages = inputs'.firefox-addons.packages;
              inherit pkgs;
            }
          );
        };

        stylix.targets.zen-browser.profileNames = lib.mkIf config.programs.zen-browser.enable [
          "default"
        ];
      };

  };
}
