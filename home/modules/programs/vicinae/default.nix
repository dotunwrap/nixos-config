{ vicinae, vicinae-extensions, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.vicinae;
  inherit (pkgs.stdenv.hostPlatform) system;
  # vicinae deliberately doesn't follow our nixpkgs (see flake.nix), so its
  # glibc is older than the system's. The host Mesa in /run/opengl-driver then
  # fails to load inside its process (GLIBC_x.y not found) and both EGL and
  # Vulkan break. Use a Mesa from vicinae's own pin so the libc versions match.
  # TODO: This should be removed when the issue #2040 is resolved
  mesa = vicinae.inputs.nixpkgs.legacyPackages.${system}.mesa;
  icds = lib.concatMapStringsSep ":" (n: "${mesa}/share/vulkan/icd.d/${n}_icd.x86_64.json") [
    "intel"
    "radeon"
    "nouveau"
  ];
in
{
  config = lib.mkIf cfg.enable {
    home.activation.restartVicinaeServer = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      run systemctl --user restart vicinae.service || true
    '';

    programs.vicinae = {
      systemd = {
        enable = lib.mkDefault true;
        autoStart = lib.mkDefault true;
        environment = {
          USE_LAYER_SHELL = lib.mkDefault 1;
          QSG_RHI_BACKEND = lib.mkDefault "vulkan";
          VK_DRIVER_FILES = lib.mkDefault icds;
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
