{ lib, ... }:
{
  den.default.nixos.system.stateVersion = lib.mkDefault "25.05";
  den.default.homeManager.home.stateVersion = lib.mkDefault "24.11";
}
