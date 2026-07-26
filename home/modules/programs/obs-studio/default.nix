_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.obs-studio;
in
{
  config = lib.mkIf cfg.enable {
    programs.obs-studio.plugins =
      with pkgs.obs-studio-plugins;
      lib.mkDefault [
        droidcam-obs
      ];
  };
}
