{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      # NOTE: Home Manager is NixOS-integrated: home-manager.users.<name>
      # inside each host's own nixosSystem.
      hmConfig =
        { host, user }:
        config.flake.nixosConfigurations.${host}.config.home-manager.users.${user};

      # NOTE: regression pin for c8bca61: stylix's x11/sxiv targets both
      # default to enabled upstream and write ~/.Xresources; only dwm hosts
      # should pull that in, discriminated the same way modules/defaults.nix
      # does: xsession.enable.
      stylixTargetFailures =
        builtins.concatMap
          (
            { host, user }:
            let
              profile = "${user}@${host}";
              cfg = hmConfig { inherit host user; };
              dwm = cfg.xsession.enable;
              x11 = cfg.stylix.targets.x11.enable;
              sxiv = cfg.stylix.targets.sxiv.enable;
            in
            lib.optional (x11 != dwm)
              "${profile}: stylix.targets.x11.enable (${lib.boolToString x11}) != bundles.dwm.enable (${lib.boolToString dwm})"
            ++ lib.optional sxiv "${profile}: stylix.targets.sxiv.enable is true (writes ~/.Xresources unconditionally)"
          )
          [
            {
              host = "chikyuu";
              user = "gabby";
            }
            {
              host = "kaiousei";
              user = "gabby";
            }
            {
              host = "meiousei";
              user = "gabby";
            }
            {
              host = "meiousei";
              user = "nia";
            }
            {
              host = "suisei";
              user = "nia";
            }
          ];
    in
    {
      checks.stylix-xresources-regression = pkgs.runCommand "stylix-xresources-regression" { } (
        if stylixTargetFailures == [ ] then
          "touch $out"
        else
          throw ''
            stylix ~/.Xresources regression check(s) failed:
            ${lib.concatMapStringsSep "\n" (m: "  - ${m}") stylixTargetFailures}
          ''
      );
    };
}
