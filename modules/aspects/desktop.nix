{
  # Formerly nixos/modules/programs/display-managers/ly, used by both the dwm
  # and niri bundles, plus the 12 home programs dwm and niri both enabled
  # identically (bitwarden, obs-studio, onlyoffice, pavucontrol, protonvpn,
  # qbittorrent, signal, spotify, tor-browser, vesktop, wezterm, zen-browser).
  # Included by both den.aspects.dwm and den.aspects.niri rather than
  # duplicated in each.
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

        # NOTE:
        # nixpkgs' default ly PAM stack is `auth substack login`, which inherits
        # the system `login` service's ordering: pam_fprintd (sufficient) before
        # pam_unix (sufficient). That means pressing Enter after typing the
        # correct password still blocks on a fingerprint read first, since PAM
        # evaluates the stack top-to-bottom in one call.
        # (https://github.com/NixOS/nixpkgs/issues/171136)
        #
        # We are going to resolve this by just reordering `login` itself so
        # pam_unix is tried before pam_fprintd. ly, and tty logins (which share
        # the `login` PAM service), then try the typed password first and only
        # fall back to the fingerprint reader afterward.
        security.pam.services.login.rules.auth.fprintd.order = lib.mkIf config.services.fprintd.enable (
          config.security.pam.services.login.rules.auth.unix.order + 50
        );
      };

    provides.to-users.homeManager =
      { lib, pkgs, ... }:
      {
        # Formerly bitwarden/pavucontrol/protonvpn/qbittorrent/signal/spotify/
        # tor-browser's own custom modules -- none are native Home Manager
        # options (unlike wezterm/obs-studio/zen-browser below), each was
        # just `home.packages = [ <the one package> ];` behind an enable
        # flag, so they fold directly into one list. (onlyoffice/vesktop's
        # own custom modules had empty bodies -- enabling them currently
        # does nothing, so they're dropped rather than ported as no-ops.)
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
