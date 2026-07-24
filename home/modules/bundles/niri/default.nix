{ vicinae-extensions, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.niri;
  inherit (pkgs.stdenv.hostPlatform) system;
in

{
  options.bundles.niri = {
    enable = lib.mkEnableOption "The niri bundle.";
  };

  config = lib.mkIf cfg.enable {
    xdg.userDirs.extraConfig.SCREENSHOTS = "${config.home.homeDirectory}/Pictures/Screenshots";

    programs = {
      bitwarden.enable = lib.mkDefault true;
      imagemagick.enable = lib.mkDefault true;
      obs-studio = {
        enable = lib.mkDefault true;
        plugins =
          with pkgs.obs-studio-plugins;
          lib.mkDefault [
            droidcam-obs
          ];
      };
      onlyoffice.enable = lib.mkDefault true;
      pavucontrol.enable = lib.mkDefault true;
      protonvpn.enable = lib.mkDefault true;
      qbittorrent.enable = lib.mkDefault true;
      signal.enable = lib.mkDefault true;
      spotify.enable = lib.mkDefault true;
      tor-browser.enable = lib.mkDefault true;
      vesktop.enable = lib.mkDefault true;
      vicinae = {
        enable = lib.mkDefault true;
        systemd = {
          enable = lib.mkDefault true;
          autoStart = lib.mkDefault true;
          environment = {
            USE_LAYER_SHELL = lib.mkDefault 1;
          };
        };
        settings = {
          close_on_focus_loss = lib.mkDefault true;
          consider_preedit = lib.mkDefault true;
          pop_to_root_on_close = lib.mkDefault true;
          basic_usage_statistics = false;
          providers = {
            "@dagimg-dot/vicinae-extension-wifi-commander-0" = {
              preferences = {
                network-cli-tool = "nmcli";
              };
            };
          };
        };
        extensions =
          with vicinae-extensions.packages.${system};
          lib.mkDefault [
            # NOTE: bluetooth and systemd are currently not building for nix-unstable
            # https://github.com/vicinaehq/extensions/blob/ca74eede9a778a9373c8f5fd221b0a5026dcd1ef/flake.nix#L65
            # bluetooth
            # systemd
            nix
            wifi-commander
            pulseaudio
            niri
            it-tools
          ];
      };
      wayland-utils.enable = lib.mkDefault true;
      wezterm.enable = lib.mkDefault true;
      wl-clipboard.enable = lib.mkDefault true;
      zen-browser = {
        enable = lib.mkDefault true;
        setAsDefaultBrowser = lib.mkDefault true;
      };
    };

    misc.niri-config.enable = true;

    services = {
      awww.enable = lib.mkDefault true;
      mako.enable = lib.mkDefault true;
      playerctld.enable = lib.mkDefault true;
      swayidle = {
        enable = true;
        events.before-sleep = "";
      };
    };
  };
}
