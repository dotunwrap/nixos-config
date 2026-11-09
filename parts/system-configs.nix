{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  # Aliased here, before the per-host submodule below rebinds `config` to its
  # own (shadowed) scope -- this is the only way to reach the top-level
  # flake-parts config (e.g. `den.hosts.*`) from inside that submodule.
  flakeConfig = config;

  cfg = config.dotunwrap.nixosConfigurations;

  configs = builtins.mapAttrs (_: config: config.finalSystem) cfg;
in
{
  options = {
    dotunwrap.nixosConfigurations = lib.mkOption {
      type = lib.types.attrsOf (
        lib.types.submodule (
          {
            name,
            config,
            ...
          }:
          {
            options = {
              nixpkgs = lib.mkOption {
                type = lib.types.unspecified;
                default = inputs.nixpkgs;
              };
              system = lib.mkOption { type = lib.types.enum [ "x86_64-linux" ]; };

              modules = lib.mkOption {
                type = lib.types.listOf lib.types.unspecified;
                default = [ ];
              };

              entryPoint = lib.mkOption {
                type = lib.types.unspecified;
                readOnly = true;
              };

              finalModules = lib.mkOption {
                type = lib.types.listOf lib.types.unspecified;
                readOnly = true;
              };

              configFolder = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };

              bootloader = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };

              hardware = lib.mkOption {
                type = lib.types.str;
                readOnly = true;
              };

              finalSystem = lib.mkOption {
                type = lib.types.unspecified;
                readOnly = true;
              };
            };

            config = {
              configFolder = "${self}/nixos/configurations";
              entryPoint = import "${config.configFolder}/${name}.nix" (inputs // { inherit self; });
              bootloader = "${config.configFolder}/bootloader/${name}.nix";
              hardware = "${config.configFolder}/hardware/${name}.nix";

              finalModules = [
                { boot.tmp.cleanOnBoot = true; }
                { networking.hostName = name; }
                { nix.flakes.enable = true; }
                { system.configurationRevision = self.rev or "${self.dirtyRev or "unknown"}-dirty"; }
                { documentation.man.enable = true; }
                { documentation.man.cache.enable = true; }
                { nixpkgs.hostPlatform.system = config.system; }
                {
                  nixpkgs.overlays = [
                    inputs.rust-overlay.overlays.default
                    # NOTE: also needed here, not just on the Home Manager side, now that
                    # useGlobalPkgs means every migrated user's `pkgs` IS this shared instance --
                    # a per-user `nixpkgs.overlays` under home-manager.users.<name> is a no-op.
                    inputs.claude-code-overlay.overlays.default
                    inputs.niri-flake.overlays.niri
                  ];
                }
                inputs.stylix.nixosModules.stylix
                inputs.niri-flake.nixosModules.niri
                inputs.vicinae.nixosModules.default
                # NOTE: Vicinae's NixOS module has the input-server enabled by default. Implicit actions bad.
                # I have spoken with contributors on their Discord server, and this is something that will be
                # changed later.
                { programs.vicinae.input-server.enable = lib.mkDefault false; }
              ]
              ++ config.modules
              ++ builtins.attrValues {
                inherit (config) entryPoint bootloader hardware;
              }
              ++ builtins.attrValues self.nixosModules
              ++ [ (flakeConfig.den.hosts.x86_64-linux.${name}.mainModule or { }) ]
              ++ (
                let
                  # Which host-attached users are migrated to NixOS-integrated Home
                  # Manager. NOTE: niri-flake's own NixOS module (unconditionally in
                  # this baseline, below) already injects its HM module
                  # (`self.homeModules.config`/`.stylix`) into `home-manager.sharedModules`
                  # for every user the instant it detects NixOS-integrated HM
                  # (`options ? home-manager`) -- adding `inputs.niri-flake.homeModules.*`
                  # again here ourselves double-declares the same options
                  # (`programs.niri.finalConfig` etc). Confirmed by reading niri-flake's
                  # own source directly, not by inference: don't re-add it.
                  homeUsers = {
                    chikyuu = [ "gabby" ];
                    kaiousei = [ "gabby" ];
                    meiousei = [
                      "gabby"
                      "nia"
                    ];
                    suisei = [ "nia" ];
                  };
                  # Everything parts/home-configs.nix's baseline supplied, minus
                  # `nixpkgs.overlays` (ineffective per-user under useGlobalPkgs -- fixed
                  # at the host level above instead), minus the explicit
                  # `home.username`/`home.homeDirectory` (NixOS-integration derives both
                  # from the matching `users.users.<name>` account), and minus
                  # niri-flake's HM modules (see note above -- niri-flake's own NixOS
                  # module already delivers them automatically via sharedModules).
                  commonBaseline = [
                    { systemd.user.startServices = "sd-switch"; }
                    { news.display = "silent"; }
                    # NOTE: stylix's HM module unconditionally re-applies its own
                    # per-target overlays via `nixpkgs.overlays` (stylix.overlays.enable
                    # defaults true) -- forbidden under useGlobalPkgs, and redundant
                    # anyway since the NixOS-side stylix module (also in finalModules)
                    # already applies the same overlays to the one shared `pkgs`.
                    { stylix.overlays.enable = false; }
                    inputs.stylix.homeModules.stylix
                    inputs.zen-browser.homeModules.twilight
                    inputs.vicinae.homeManagerModules.default
                  ]
                  ++ builtins.attrValues self.homeManagerModules;
                  users = homeUsers.${name} or [ ];
                in
                lib.optional (users != [ ]) {
                  # `home-manager.*` only exists once the `home-manager` NixOS module is
                  # actually imported (triggered by >=1 user with classes=["homeManager"]
                  # in modules/hosts.nix) -- a host with none (europa, today) never declares
                  # this namespace at all, so this must stay conditioned on the same
                  # `users != []` check, not applied as a blanket default to every host.
                  home-manager = {
                    useGlobalPkgs = true;
                    useUserPackages = true;
                  };
                }
                ++ map (username: {
                  home-manager.users.${username}.imports = commonBaseline ++ [
                    (import "${self}/home/configurations/${username}-at-${name}.nix" (inputs // { inherit self; }))
                  ];
                }) users
              );

              finalSystem = config.nixpkgs.lib.nixosSystem {
                modules = config.finalModules;
              };
            };
          }
        )
      );
    };
  };

  config.flake.nixosConfigurations = configs;
}
