{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  hostNames = builtins.attrNames (config.den.hosts.x86_64-linux or { });

  # NOTE: not Den's `den.schema.hm-host.includes`; that fires once per HM
  # user, duplicating every entry on multi-user hosts (saw it on meiousei).
  homeManagerBaseline = [
    { systemd.user.startServices = "sd-switch"; }
    { news.display = "silent"; }
    # NOTE: stylix's HM overlays are forbidden under useGlobalPkgs, and
    # redundant anyway: the NixOS-side module already applies them.
    { stylix.overlays.enable = false; }
    inputs.stylix.homeModules.stylix
    inputs.zen-browser.homeModules.twilight
    inputs.vicinae.homeManagerModules.default
  ];

  mkHost =
    name:
    let
      hasHomeManagerUsers = (config.den.hosts.x86_64-linux.${name}.users or { }) != { };
    in
    inputs.nixpkgs.lib.nixosSystem {
      modules = [
        { boot.tmp.cleanOnBoot = true; }
        { system.configurationRevision = self.rev or "${self.dirtyRev or "unknown"}-dirty"; }
        { documentation.man.enable = true; }
        { documentation.man.cache.enable = true; }
        { nixpkgs.hostPlatform.system = "x86_64-linux"; }
        {
          nixpkgs.overlays = [
            inputs.rust-overlay.overlays.default
            # NOTE: needed here too; useGlobalPkgs makes a per-user
            # `nixpkgs.overlays` a no-op.
            inputs.claude-code-overlay.overlays.default
            inputs.niri-flake.overlays.niri
          ];
        }
        inputs.stylix.nixosModules.stylix
        # NOTE: niri-flake's NixOS module already injects its HM module via
        # sharedModules; re-adding it via homeManagerBaseline would double-declare options.
        inputs.niri-flake.nixosModules.niri
        inputs.vicinae.nixosModules.default
        # NOTE: input-server defaults to enabled upstream; off until that changes.
        { programs.vicinae.input-server.enable = lib.mkDefault false; }
        (config.den.hosts.x86_64-linux.${name}.mainModule or { })
      ]
      # NOTE: a host with no HM users (europa) never declares `home-manager.*`
      # at all, so this can't be a blanket default.
      ++ lib.optional hasHomeManagerUsers {
        home-manager = {
          useGlobalPkgs = true;
          useUserPackages = true;
          sharedModules = homeManagerBaseline;
        };
      };
    };
in
{
  flake-file.inputs = {
    niri-flake = {
      # NOTE: fork of sodiboo/niri-flake; upstream is stale and broken
      # against current nixpkgs (still needs removed libdisplay-info_0_2).
      url = "github:epireyn/niri-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    zen-browser = {
      url = "github:0xc000022070/zen-browser-flake";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        home-manager.follows = "home-manager";
      };
    };

    rust-overlay = {
      url = "github:oxalica/rust-overlay";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    claude-code-overlay = {
      url = "github:sadjow/claude-code-nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };

    stylix = {
      url = "github:nix-community/stylix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems-future";
        flake-parts.follows = "flake-parts";
      };
    };

    # NOTE: vicinae intentionally doesn't follow our nixpkgs; a large
    # Qt6/C++ build, any drift busts its cachix cache. See devenv.nix.
    vicinae = {
      url = "github:vicinaehq/vicinae";
      inputs.systems.follows = "systems";
    };
    vicinae-extensions = {
      url = "github:vicinaehq/extensions";
      inputs = {
        nixpkgs.follows = "vicinae/nixpkgs";
        vicinae.follows = "vicinae";
        systems.follows = "systems";
      };
    };
  };

  flake.nixosConfigurations = lib.genAttrs hostNames mkHost;
}
