{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    poweralertd
  ];

  services.upower.enable = true;
}
