{ config, lib, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      hmConfig = profile: config.flake.homeConfigurations.${profile}.config;

      # NOTE: regression pin for c8bca61 -- stylix's x11/sxiv targets both
      # default to enabled upstream and both write ~/.Xresources; only the
      # dwm/X11 bundle should ever pull that in.
      stylixTargetFailures =
        builtins.concatMap
          (
            profile:
            let
              cfg = hmConfig profile;
              dwm = cfg.bundles.dwm.enable;
              x11 = cfg.stylix.targets.x11.enable;
              sxiv = cfg.stylix.targets.sxiv.enable;
            in
            lib.optional (x11 != dwm)
              "${profile}: stylix.targets.x11.enable (${lib.boolToString x11}) != bundles.dwm.enable (${lib.boolToString dwm})"
            ++ lib.optional sxiv "${profile}: stylix.targets.sxiv.enable is true (writes ~/.Xresources unconditionally)"
          )
          [
            "gabby@chikyuu"
            "gabby@kaiousei"
            "gabby@meiousei"
            "nia@meiousei"
            "nia@suisei"
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
