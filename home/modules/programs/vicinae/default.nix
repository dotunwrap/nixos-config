{ vicinae-extensions, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vicinae;
  inherit (pkgs.stdenv.hostPlatform) system;
in
{
  config = lib.mkIf cfg.enable {
    home.activation.restartVicinaeServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run vicinae server --replace || true
    '';

    programs.vicinae = {
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
  };
}
