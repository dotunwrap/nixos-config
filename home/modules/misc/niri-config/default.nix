_:
{
  lib,
  config,
  pkgs,
  ...
}:
let
  cfg = config.misc.niri-config;

  setWallpaper = pkgs.writeShellScript "set-wallpaper" ''
    until ${pkgs.awww}/bin/awww query >/dev/null 2>&1; do sleep 0.2; done
    exec ${pkgs.awww}/bin/awww img ${config.stylix.image}
  '';
in
{
  config = lib.mkIf cfg.enable {
    home.activation.reloadNiri = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      if [ -n "''${NIRI_SOCKET:-}" ]; then
        run ${config.programs.niri.package}/bin/niri msg action load-config-file || true
      fi
    '';

    programs.niri.settings =
      let
        importDefaultSettings = f: import f { inherit lib pkgs config; };
      in
      {
        input = importDefaultSettings ./input.nix;
        binds = importDefaultSettings ./binds.nix;
        layout = importDefaultSettings ./layout.nix;
        window-rules = importDefaultSettings ./window-rules.nix;

        clipboard.disable-primary = lib.mkDefault true;
        prefer-no-csd = lib.mkDefault true;
        overview.zoom = lib.mkDefault 0.5;

        environment = {
          NIX_OZONE_WL = lib.mkDefault "1";
          MOZ_ENABLE_WAYLAND = lib.mkDefault "1";
          ELECTRON_OZONE_PLATFORM_HINT = lib.mkDefault "1";
          QT_QPA_PLATFORMTHEME = lib.mkDefault "gtk3";
          QT_STYLE_OVERRIDE = lib.mkDefault "adwaita-dark";
        };

        spawn-at-startup = [
          { command = [ "${setWallpaper}" ]; }
        ];
      };
  };
}
