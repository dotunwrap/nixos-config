{ pkgs, lib, ... }:

{
  mySystem = {
    hyprland.enable = lib.mkDefault true;
    zsh.enable = lib.mkDefault true;
    sddm.enable = lib.mkDefault false;
    autologin.enable = lib.mkDefault false;
  };

  time.timeZone = "America/New_York";
  i18n.defaultLocale = "en_US.UTF-8";

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    jack.enable = true;
  };

  fonts.packages = with pkgs; [
    corefonts
    pkgs.nerd-fonts.jetbrains-mono
    pkgs.nerd-fonts.iosevka
    pkgs.nerd-fonts.fira-code
  ];

  services.upower.enable = true;

  security.polkit.enable = true;

  hardware = {
    enableAllFirmware = true;
    
    bluetooth.enable = true;
    bluetooth.powerOnBoot = true;
  };

  programs.dconf.enable = true;

  systemd = {
    user.services.polkit-gnome-authentication-agent-1 = {
      description = "polkit-gnome-authentication-agent-1";
      wantedBy = ["graphical-session.target"];
      wants = ["graphical-session.target"];
      after = ["graphical-session.target"];
      serviceConfig = {
        Type = "simple";
        ExecStart = "${pkgs.polkit_gnome}/libexec/polkit-gnome-authentication-agent-1";
        Restart = "on-failure";
        RestartSec = 1;
        TimeoutStopSec = 10;
      };
    };
  };
}
