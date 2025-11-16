_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.bundles.gaming;
in
{
  options = {
    bundles.gaming = {
      enable = lib.mkEnableOption "The gaming bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    programs = {
      steam = {
        enable = true;
        extraCompatPackages = [ pkgs.proton-ge-bin ];
      };
      protonup-ng.enable = true;
    };

    services.hardware.openrgb = {
      enable = true;
      package = pkgs.openrgb-with-all-plugins;
    };
  };
}
