_:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.niri;
in

{
  options = {
    bundles.niri = {
      enable = lib.mkEnableOption "The niri bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    fonts.packages = with pkgs; [
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

    programs = {
      niri.enable = true;
      display-managers.ly.enable = true;
    };

    services = {
      displayManager.defaultSession = "niri";
    };

    systemd.user.services.hyprpolkitagent = {
      description = "Hyprland Polkit Authentication Agent";
      wantedBy = [ "graphical-session.target" ];
      wants = [ "graphical-session.target" ];
      after = [ "graphical-session.target" ];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.hyprpolkitagent}/libexec/hyprpolkitagent";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };

    security.soteria.enable = true;

    environment = {
      systemPackages = [ pkgs.hyprpolkitagent ];
    };
  };
}
