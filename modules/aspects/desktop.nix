{
  # NOTE: shared by den.aspects.dwm and den.aspects.niri rather than duplicated.
  den.aspects.desktop = {
    nixos =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        services.displayManager.ly = {
          enable = true;
          package = pkgs.ly;
          settings = {
            bigclock = "en";
            clear_password = true;
            default_input = "password";
            vi_mode = true;
            box_title = "${config.networking.hostName}";
          };
        };

        # NOTE: ly inherits `login`'s PAM ordering (pam_fprintd before
        # pam_unix, both "sufficient"), so Enter after a correct password
        # still blocks on a fingerprint read first (nixpkgs#171136). Reorder
        # `login` itself so the typed password is tried first; tty logins
        # get the same fix for free since they share the `login` PAM service.
        security.pam.services.login.rules.auth.fprintd.order = lib.mkIf config.services.fprintd.enable (
          config.security.pam.services.login.rules.auth.unix.order + 50
        );
      };

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      {
        home.packages = [
          pkgs.bitwarden-desktop
          pkgs.bitwarden-cli
          pkgs.pavucontrol
          pkgs.proton-vpn
          pkgs.qbittorrent
          pkgs.signal-desktop
          pkgs.spotify
          pkgs.tor-browser
        ];

        programs = {
          zen-browser.enable = lib.mkDefault true;

          obs-studio.enable = lib.mkDefault true;

          wezterm.enable = lib.mkDefault true;
          wezterm.settings = {
            hide_tab_bar_if_only_one_tab = true;
            window_padding = {
              left = 0;
              right = 0;
              top = 0;
              bottom = 0;
            };
            window_decorations = "NONE";
            integrated_title_buttons = [ ];
            keys = [
              {
                key = "Enter";
                mods = "ALT";
                action = lib.generators.mkLuaInline "wezterm.action.DisableDefaultAssignment";
              }
            ];
          };
        };
      };
  };
}
