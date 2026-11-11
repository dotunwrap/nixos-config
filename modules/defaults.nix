{
  den,
  inputs,
  lib,
  ...
}:
{
  # Reusable Den batteries applied everywhere rather than hand-rolled:
  # - hostname: sets networking.hostName from each host's own name --
  #   replaces a `networking.hostName = "<name>";` line we used to repeat in
  #   every host file (and again in modules/system-configs.nix's baseline).
  # - inputs': gives every nixos/homeManager-class module `inputs'` (system
  #   pre-selected) as a module arg, replacing
  #   `inputs.X.packages.${pkgs.stdenv.hostPlatform.system}.Y` with
  #   `inputs'.X.packages.Y` wherever that pattern was repeated (this file,
  #   modules/aspects/niri.nix, modules/users/*).
  # - user-shell "zsh": sets the login shell and enables `programs.zsh` at
  #   both the NixOS and Home Manager levels -- replaces three separate
  #   zsh-enabling spots (nixos below, homeManager below, each user's own
  #   `shell = pkgs.zsh;`).
  den.default = {
    includes = [
      den.batteries.hostname
      den.batteries.inputs'
      (den.batteries.user-shell "zsh")
    ];

    # Formerly nixos/modules/bundles/base, nixos/modules/core/{cachix,nix},
    # and nixos/configurations/bootloader/* -- all unconditional on every
    # host with no gating at all, so they move to den.default.nixos
    # (broadcast to every host) rather than becoming aspects some host would
    # need to `includes`. (The development bundle, unlike these, stays its
    # own aspect -- see modules/aspects/development.nix -- since it's
    # something a host or user should be able to opt out of, even though
    # every one currently includes it.)
    nixos =
      { pkgs, inputs', ... }:
      {
        system.stateVersion = lib.mkDefault "25.05";

        # Formerly nixos/configurations/bootloader/<host>.nix -- identical on
        # all 5 hosts today, but mkDefault throughout (not plain assignment) so
        # any host can cleanly override a single field with a plain assignment
        # of its own, rather than needing lib.mkForce to fight a same-priority
        # conflict.
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

        # Formerly nixos/modules/core/{cachix,nh,nix,flake} -- all unconditional
        # on every host (flake's own `nix.flakes.enable` gate was always
        # switched on unconditionally from parts/system-configs.nix's own
        # baseline, never actually gated).
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
            substituters = [
              "https://cache.nixos.org"
              "https://niri-epireyn.cachix.org"
              "https://nix-community.cachix.org"
              "https://vicinae.cachix.org"
              "https://yazi.cachix.org"
            ];
            trusted-public-keys = [
              "niri-epireyn.cachix.org-1:tlVyFN7CtsDT+ZcLPS+ekFWeT1X6X4OqvWqbBMyIzFA="
              "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
              "vicinae.cachix.org-1:1kDrfienkGHPYbkpNj1mWTr7Fm1+zcenzgTizIcI3oc="
              "yazi.cachix.org-1:Dcdz63NZKfvUCbDGngQDAZq6kOroIrFoyO064uvLh8k="
            ];
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

    # Formerly home/modules/bundles/base (force-enabled for every profile
    # via home/modules/misc/home, bypassing activeBundles entirely) --
    # unconditional on every home-manager user with no gating at all, so it
    # moves to den.default.homeManager (broadcast to every user).
    # `monolisa.package` keeps the same per-user override point the old
    # `bundles.base.monolisaVersion` option gave nia's profile (see
    # modules/users/nia.nix).
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

        # Formerly home/modules/programs/nvim's own `programs.nvim.package`
        # option -- not native, and not nested under `programs.nvim` here to
        # avoid colliding with HM's own native `programs.neovim`-adjacent
        # options. nia's profile overrides this the same way she overrides
        # `monolisa.package` (see modules/users/nia.nix).
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
              # Formerly home/modules/programs/nvim -- stylix-wrapped the same
              # way the original module did.
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

            # Formerly home/modules/programs/starship's own `.prompt` option,
            # which just selected which settings preset to load -- "pure" is
            # the only one that ever existed, so it's inlined directly.
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
              # Formerly home/modules/programs/shells/shellAliases.nix, which
              # read `config.bundles.dwm.enable`/`config.bundles.niri.enable`
              # directly -- dwm/niri are now host-driven aspects, not per-user
              # bundle flags, so the discriminator is whatever a dwm host's own
              # aspect already sets on every one of its users: `xsession.enable`.
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

          # Formerly home/modules/themes/default.nix's shared stylix dispatch,
          # common to every theme (everforest/catppuccin) rather than
          # theme-specific -- each host's own `provides.to-users.homeManager`
          # only needs to set `stylix.image`/`stylix.base16Scheme` (+ any
          # theme-specific cursor/freetube overrides) on top of this.
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
              # x11 and sxiv targets default to enabled regardless of session
              # type and both write to ~/.Xresources; only wire x11 up on X11
              # (dwm) hosts, and sxiv not at all since we don't use it, so
              # Wayland/niri hosts don't get a ~/.Xresources.
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
