_:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.plasma;
in

{
  options = {
    bundles.plasma = {
      enable = lib.mkEnableOption "The KDE Plasma bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        corefonts

        noto-fonts
        noto-fonts-cjk-sans
        noto-fonts-color-emoji

        font-awesome

        garamond-libre

        nerd-fonts.jetbrains-mono
        nerd-fonts.fira-code
        nerd-fonts.symbols-only
      ];
    };

    services = {
      desktopManager.plasma6.enable = true;
      displayManager.sddm.enable = true;
      displayManager.sddm.wayland.enable = true;
    };

    environment.systemPackages = with pkgs; [
      kdePackages.discover # Optional: Software center for Flatpaks/firmware updates
      kdePackages.kcalc # Calculator
      kdePackages.kcharselect # Character map
      kdePackages.kclock # Clock app
      kdePackages.kcolorchooser # Color picker
      kdePackages.ksystemlog # System log viewer
      kdePackages.sddm-kcm # SDDM configuration module
      kdiff3 # File/directory comparison tool

      kdePackages.partitionmanager # Disk and partition management
      hardinfo2 # System benchmarks and hardware info
      wayland-utils # Wayland diagnostic tools
      wl-clipboard # Wayland copy/paste support
    ];

  };
}
