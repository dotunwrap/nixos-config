{ pkgs }:
{
  garrett = {
    isNormalUser = true;
    shell = pkgs.zsh;
    extraGroups = [
      "wheel"
      "audio"
      "networkmanager"
    ];
  };
}
