{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  hostNames = builtins.attrNames (config.den.hosts.x86_64-linux or { });

  # NOTE: set via `home-manager.sharedModules` (applies once per host), not
  # Den's `den.schema.hm-host.includes` -- that hook fires once per HM user on
  # a host, which duplicated every list entry on hosts with >1 user (confirmed
  # via an "option already declared" eval error on meiousei).
  homeManagerBaseline = [
    { systemd.user.startServices = "sd-switch"; }
    { news.display = "silent"; }
    # NOTE: stylix's HM module unconditionally re-applies its own per-target
    # overlays via `nixpkgs.overlays` (stylix.overlays.enable defaults true)
    # -- forbidden under useGlobalPkgs, and redundant anyway since the
    # NixOS-side stylix module (below) already applies the same overlays to
    # the one shared `pkgs` instance.
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
            # NOTE: also needed here, not just on the Home Manager side --
            # useGlobalPkgs means every migrated user's `pkgs` IS this shared
            # instance, so a per-user `nixpkgs.overlays` is a no-op.
            inputs.claude-code-overlay.overlays.default
            inputs.niri-flake.overlays.niri
          ];
        }
        inputs.stylix.nixosModules.stylix
        # NOTE: niri-flake's own NixOS module already injects its HM module
        # into `home-manager.sharedModules` once it detects NixOS-integrated
        # HM -- adding it again via `homeManagerBaseline` would
        # double-declare options.
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
      # NOTE: fork of sodiboo/niri-flake; upstream is stale and broken against
      # current nixpkgs (still requires the removed libdisplay-info_0_2), this
      # fork tracks nixpkgs properly.
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

    # NOTE: vicinae intentionally does NOT follow our nixpkgs: it's a large
    # Qt6/CMake/C++ build, so any drift between our nixpkgs pin and vicinae's
    # own guarantees a cache miss against vicinae.cachix.org and a
    # from-source rebuild. We prioritize build speed (real cache hits) over
    # lock file dedup here; see nix-auto-follow's `--ignore vicinae` in
    # devenv.nix.
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
