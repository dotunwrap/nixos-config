{ inputs, ... }:
let
  themes = import ../_themes.nix;
in
{
  den.aspects.gabby = {
    # Formerly nixos/configurations/users/gabby.nix -- lands on
    # users.users.gabby on every host gabby is declared on.
    user =
      { pkgs, ... }:
      {
        isNormalUser = true;
        shell = pkgs.zsh;
        extraGroups = [
          "wheel"
          "audio"
          "networkmanager"
        ];
      };

    # Formerly home/configurations/shared/gabby/default.nix -- cross-host,
    # not tied to any one of gabby's hosts (chikyuu/kaiousei/meiousei).
    homeManager =
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
              inherit (inputs) firefox-addons;
              inherit system pkgs;
            }
          );
        };

        stylix.targets.zen-browser.profileNames = lib.mkIf config.programs.zen-browser.enable [
          "default"
        ];
      };

    # Theme+wallpaper is her own choice, not her host's -- set per host she's
    # actually on (she doesn't use the same one everywhere), from her own
    # file, rather than a host deciding it for whoever's logged in.
    provides = {
      chikyuu.homeManager = themes.everforest {
        image = ../../../assets/wallpapers/stephen_njoto.png;
      };
      kaiousei.homeManager = themes.catppuccin {
        image = ../../../assets/wallpapers/anyb-girl.png;
      };
      meiousei.homeManager = themes.catppuccin {
        image = ../../../assets/wallpapers/anyb-girl.png;
      };
    };
  };
}
