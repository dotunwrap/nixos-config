{
  self,
  inputs,
  config,
  lib,
  ...
}:
let
  hostNames = builtins.attrNames (config.den.hosts.x86_64-linux or { });

  # Set via `home-manager.sharedModules` (applies once per host), not Den's
  # `den.schema.hm-host.includes` -- that hook fires once per HM user on a
  # host, which duplicated every list entry on hosts with >1 user (confirmed
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
        # niri-flake's own NixOS module already injects its HM module into
        # `home-manager.sharedModules` once it detects NixOS-integrated HM --
        # adding it again via `homeManagerBaseline` would double-declare options.
        inputs.niri-flake.nixosModules.niri
        inputs.vicinae.nixosModules.default
        # input-server defaults to enabled upstream; off until that changes.
        { programs.vicinae.input-server.enable = lib.mkDefault false; }
        (config.den.hosts.x86_64-linux.${name}.mainModule or { })
      ]
      # A host with no HM users (europa) never declares `home-manager.*` at
      # all, so this can't be a blanket default.
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
