{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  hostNames = builtins.attrNames (config.den.hosts.x86_64-linux or { });

  # Everything every host-integrated home-manager user needs regardless of
  # which aspects they include: the third-party HM flake modules, plus the
  # handful of tiny baseline tweaks every profile used to carry via
  # parts/home-configs.nix. Set once per host (via `home-manager.
  # sharedModules`, HM's own native "apply to every user" option) rather
  # than threading it through Den's `den.schema.hm-host.includes` -- that
  # hook turned out to fire once per home-manager user on a host, not once
  # per host, so a list-valued option like `sharedModules` got every entry
  # duplicated for any host with more than one HM user (confirmed via a
  # NixOS "option already declared" eval error on meiousei, which has both
  # gabby and nia).
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
        # NOTE: niri-flake's own NixOS module (unconditionally in this
        # baseline) already injects its HM module
        # (`self.homeModules.config`/`.stylix`) into
        # `home-manager.sharedModules` for every user the instant it detects
        # NixOS-integrated HM (`options ? home-manager`) -- adding
        # `inputs.niri-flake.homeModules.*` again ourselves in
        # `homeManagerBaseline` would double-declare the same options
        # (`programs.niri.finalConfig` etc). Confirmed by reading niri-flake's
        # own source directly: don't re-add it.
        inputs.niri-flake.nixosModules.niri
        inputs.vicinae.nixosModules.default
        # NOTE: Vicinae's NixOS module has the input-server enabled by
        # default. Implicit actions bad. I have spoken with contributors on
        # their Discord server, and this is something that will be changed
        # later.
        { programs.vicinae.input-server.enable = lib.mkDefault false; }
        (config.den.hosts.x86_64-linux.${name}.mainModule or { })
      ]
      # `home-manager.*` only exists once the `home-manager` NixOS module is
      # actually imported (triggered by >=1 user with classes=["homeManager"]
      # in modules/hosts.nix) -- a host with none (europa) never declares
      # this namespace at all, so this must stay conditioned on the same
      # check, not applied as a blanket default to every host.
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
  config.flake.nixosConfigurations = lib.genAttrs hostNames mkHost;
}
