{ pkgs, ... }:
{
  gabby = {
    isNormalUser = true;
    shell = pkgs.nushell;
    extraGroups = [
      "wheel"
      "audio"
      "networkmanager"
    ];
  };
}
