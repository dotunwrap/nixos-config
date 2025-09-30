{ pkgs, ... }:
{
  gabby = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "audio"
      "networkmanager"
    ];
  };
}
