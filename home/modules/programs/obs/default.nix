_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.obs;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ obs-studio ];
  };
}
