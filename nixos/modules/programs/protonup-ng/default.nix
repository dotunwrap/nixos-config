_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.protonup-ng;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [ protonup-ng ];
  };
}
