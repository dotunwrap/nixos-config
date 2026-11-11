{ den, ... }:
{
  den.aspects.gabby = {
    # primary-user supplies isNormalUser + wheel/networkmanager; user-shell
    # "zsh" (den.default.includes, modules/defaults.nix) supplies the shell
    # -- only the extra, not-shared-by-every-user group is left to say here.
    # Theme+wallpaper is her own choice, not her host's -- set per host
    # she's actually on (she doesn't use the same one everywhere), from her
    # own file, rather than a host deciding it for whoever's logged in.
    # Theme and wallpaper are independent batteries
    # (modules/aspects/batteries/{everforest,catppuccin,wallpaper}.nix).
    includes = [
      den.batteries.primary-user
      (den.batteries.everforest { hosts = [ "chikyuu" ]; })
      (den.batteries.catppuccin {
        hosts = [
          "kaiousei"
          "meiousei"
        ];
      })
      (den.batteries.wallpaper {
        chikyuu = ../../../assets/wallpapers/stephen_njoto.png;
        kaiousei = ../../../assets/wallpapers/anyb-girl.png;
        meiousei = ../../../assets/wallpapers/anyb-girl.png;
      })
    ];

    # Formerly nixos/configurations/users/gabby.nix -- lands on
    # users.users.gabby on every host gabby is declared on.
    user = {
      extraGroups = [ "audio" ];
    };

    # Formerly home/configurations/shared/gabby/default.nix -- cross-host,
    # not tied to any one of gabby's hosts (chikyuu/kaiousei/meiousei).
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
