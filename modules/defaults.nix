{
  den,
  inputs,
  lib,
  ...
}:
let
  caches = import ./_data/caches.nix;
in
{
  flake-file.inputs = {
    nix-auth = {
      url = "github:numtide/nix-auth";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        treefmt-nix.follows = "treefmt-nix";
      };
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    determinvim = {
      url = "github:dotunwrap/determinvim";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        nixvim.follows = "nixvim";
        systems.follows = "systems-future";
      };
    };

    yazi = {
      url = "github:sxyazi/yazi";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-utils.follows = "flake-utils";
        rust-overlay.follows = "rust-overlay";
      };
    };

    monolisa = {
      url = "git+ssh://git@github.com/dotunwrap/monolisa-font-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
      };
    };
  };

  den.default = {
    includes = [
      den.batteries.hostname
      den.batteries.inputs'
      (den.batteries.user-shell "zsh")
    ];

    # Unconditional on every host. `development` is the one exception that
    # stays its own aspect (modules/aspects/development.nix) so a host can
    # opt out of it.
    nixos =
      { pkgs, inputs', ... }:
      {
        system.stateVersion = lib.mkDefault "25.05";

        # mkDefault throughout so a host can override one field with a plain
        # assignment instead of fighting an equal-priority mkDefault with mkForce.
        boot = {
          loader = {
            systemd-boot.enable = lib.mkDefault true;
            efi.canTouchEfiVariables = lib.mkDefault true;
            timeout = lib.mkDefault 2;
          };
          initrd.enable = lib.mkDefault true;
          consoleLogLevel = lib.mkDefault 3;
        };

        environment.systemPackages = [
          pkgs.at-spi2-atk
          pkgs.cachix
          inputs'.home-manager.packages.home-manager
        ];

        hardware = {
          bluetooth = {
            enable = true;
            powerOnBoot = true;
            settings = {
              General = {
                Enable = "Source,Sink,Media,Socket";
                Experimental = true;
                FastConnectable = true;
              };
              Policy.AutoEnable = true;
            };
          };
          enableAllFirmware = true;
        };

        nixpkgs.config.allowUnfree = true;

        programs = {
          dconf.enable = true;
          screen.enable = true;

          gnupg.agent = {
            enable = true;
            pinentryPackage = pkgs.pinentry-curses;
            enableSSHSupport = true;
          };
        };

        security.polkit.enable = true;

        services = {
          pcscd.enable = true;

          dbus = {
            enable = true;
            implementation = "broker";
            packages = with pkgs; [
              dconf
              xfconf
            ];
          };
          geoclue2.enable = true;
          gvfs.enable = true;
          openssh.enable = true;
          pipewire = {
            enable = true;
            alsa = {
              enable = true;
              support32Bit = true;
            };
            pulse.enable = true;
            jack.enable = true;
          };
          printing.enable = true;
          tailscale.enable = true;
          udisks2.enable = true;
          upower.enable = true;
        };

        programs.nh = {
          enable = true;
          flake = "/etc/nixos";
          clean = {
            enable = true;
            dates = "weekly";
            extraArgs = "--keep 5 --keep-since 7d";
          };
        };

        systemd.tmpfiles.rules = [
          "L+ /etc/nixpkgs/channels/nixpkgs     - - - - ${inputs.nixpkgs}"
        ];

        nix = {
          package = lib.mkDefault pkgs.nix;
          registry.nixpkgs.flake = inputs.nixpkgs;
          nixPath = [
            "nixpkgs=/etc/nixpkgs/channels/nixpkgs"
            "/nix/var/nix/profiles/per-user/root/channels"
          ];

          # nh clean all already covers generation/gc cleanup on its own
          # schedule; leaving nix.gc.automatic on too just duplicates the work
          # and trips the warning programs.nh emits when both are enabled.
          gc.automatic = lib.mkForce false;

          optimise = {
            automatic = lib.mkDefault true;
            dates = lib.mkDefault [ "daily" ];
            persistent = lib.mkDefault true;
            randomizedDelaySec = lib.mkDefault "45min";
          };

          settings = {
            experimental-features = [
              "nix-command"
              "flakes"
            ];
            substituters = [ "https://cache.nixos.org" ] ++ map (c: c.url) caches;
            trusted-public-keys = map (c: c.key) caches;
            auto-optimise-store = lib.mkDefault true;
            # Plain assignment, not mkDefault: nixpkgs' own nix.nix module sets
            # trusted-users = [ "root" ] at normal priority, which otherwise
            # wins outright over a weaker mkDefault and silently drops "@wheel".
            trusted-users = [
              "root"
              "@wheel"
            ];
            min-free = lib.mkDefault (5 * (1024 * 1024 * 1024));
            max-free = lib.mkDefault (25 * (1024 * 1024 * 1024));
          };
        };
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
        options.monolisa.package = lib.mkOption {
          type = lib.types.package;
          default = inputs'.monolisa.packages.default;
        };

        # Top-level, not nested under `programs.nvim`, to avoid colliding with
        # HM's own native `programs.neovim`-adjacent options.
        options.nvim.package = lib.mkOption {
          type = lib.types.package;
          default = inputs'.determinvim.packages.default;
        };

        config = {
          home = {
            stateVersion = lib.mkDefault "24.11";
            sessionVariables.EDITOR = "nvim";
            packages = [
              config.monolisa.package
              (
                if config.stylix.enable && config.stylix.targets.nixvim.enable then
                  config.nvim.package.extend config.stylix.targets.nixvim.exportedModule
                else
                  config.nvim.package
              )
              pkgs.brightnessctl
              pkgs.cryptsetup
              pkgs.just
              pkgs.killall
              pkgs.magic-wormhole
              pkgs.mat2
              inputs'.nix-auth.packages.default
              pkgs.nix-output-monitor
              pkgs.p7zip
              pkgs.pulsemixer
              pkgs.wget
              pkgs.xsel
              pkgs.zip
              pkgs.unzip
            ];
          };

          xdg.userDirs = {
            enable = true;
            createDirectories = true;
            desktop = null;
            templates = null;
            publicShare = null;
            music = null;
            videos = null;
            setSessionVariables = true;
          };

          fonts.fontconfig = {
            enable = true;
            defaultFonts.monospace = lib.mkDefault [ "MonoLisa Variable" ];
          };

          programs = {
            bat.enable = true;
            gh.enable = true;
            git.enable = true;
            gpg.enable = true;
            fzf.enable = true;
            home-manager.enable = true;
            jq.enable = true;
            macchina.enable = true;
            nix-index.enable = true;
            qalculate.enable = true;
            ripgrep.enable = true;
            pay-respects.enable = true;
            starship.enable = true;

            starship.settings = lib.mkDefault {
              format = lib.concatStrings [
                "$username"
                "$hostname"
                "$directory"
                "$git_branch"
                "$git_state"
                "$git_status"
                "$cmd_duration"
                "$line_break"
                "$python"
                "$character"
              ];

              directory.style = "blue";

              character = {
                success_symbol = "[❯](purple)";
                error_symbol = "[❯](red)";
                vimcmd_symbol = "[❮](green)";
              };

              git_branch = {
                format = "[$branch]($style)";
                style = "bright-black";
              };

              git_status = {
                format = "[[(*$conflicted$untracked$modified$staged$renamed$deleted)](218) ($ahead_behind$stashed)]($style) ";
                style = "cyan";
                conflicted = "​";
                untracked = "​";
                modified = "​";
                staged = "​";
                renamed = "​";
                deleted = "​";
                stashed = "≡";
              };

              git_state = {
                format = "\([$state( $progress_current/$progress_total)]($style)\) ";
                style = "bright-black";
              };

              cmd_duration = {
                format = "[$duration]($style) ";
                style = "yellow";
              };

              python = {
                format = "[$virtualenv]($style) ";
                style = "bright-black";
                detect_extensions = [ ];
                detect_files = [ ];
              };
            };

            yazi = {
              enable = true;
              # Use the bleeding edge build from Yazi upstream.
              package = inputs'.yazi.packages.default;
              shellWrapperName = "y";
            };

            btop.settings = {
              color_theme = lib.mkDefault "gruvbox_dark";
              theme_background = lib.mkDefault false;
              vim_keys = lib.mkDefault true;
            };

            direnv = {
              nix-direnv.enable = lib.mkDefault true;
              silent = lib.mkDefault true;
              config.global.hide_env_diff = lib.mkDefault true;
            };

            eza = {
              enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
              git = lib.mkIf config.programs.git.enable true;
              icons = "auto";
              extraOptions = [ "--group-directories-first" ];
            };

            zsh = {
              autocd = lib.mkDefault true;
              # xsession.enable is the discriminator: dwm/niri are host
              # aspects, not per-user flags, so this is what a dwm host sets.
              shellAliases = {
                ll = "ls -la";
                c = if config.xsession.enable then "xsel --clipboard --input" else "wl-copy";
              };
              antidote = {
                enable = true;
                plugins = [
                  "jeffreytse/zsh-vi-mode"

                  "mattmc3/ez-compinit"

                  "getantidote/use-omz"
                  "ohmyzsh/ohmyzsh path:lib"
                  "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
                  "ohmyzsh/ohmyzsh path:plugins/sudo"

                  "mattmc3/zfunctions"
                  "zsh-users/zsh-autosuggestions"
                  "zdharma-continuum/fast-syntax-highlighting kind:defer"
                  "zsh-users/zsh-history-substring-search"
                ];
              };
            };

          };

          stylix = {
            enable = true;
            polarity = lib.mkDefault "dark";
            fonts.monospace = {
              package = lib.mkDefault config.monolisa.package;
              name = lib.mkDefault "MonoLisa Variable";
            };
            cursor = {
              size = lib.mkDefault 32;
              package = lib.mkDefault pkgs.volantes-cursors;
              name = lib.mkDefault "volantes_cursors";
            };
            targets = {
              # x11/sxiv both default to enabled upstream and write
              # ~/.Xresources regardless of session type; only x11 is wired
              # to xsession.enable, sxiv stays off (pinned by checks-stylix.nix).
              feh.enable = lib.mkIf config.xsession.enable true;
              x11.enable = lib.mkDefault config.xsession.enable;
              sxiv.enable = lib.mkDefault false;
              # NOTE: gtksourceview target causes inkscape to rebuild every hm
              # generation build.
              gtksourceview.enable = lib.mkDefault false;
            };
          };

          services = {
            mpris-proxy.enable = true;
            udiskie.enable = true;
          };
        };
      };
  };
}
