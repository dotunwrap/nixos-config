{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    at-spi2-atk
  ];

  services.dbus = {
    enable = true;
    implementation = "broker";
    packages = with pkgs; [
      xfce.xfconf
      gnome2.GConf
    ];
  };
}
