_:
{
  config,
  lib,
  ...
}:

let
  cfg = config.bundles.development;
in

{
  options = {
    bundles.development = {
      enable = lib.mkEnableOption "The development bundle.";
    };
  };

  config = lib.mkIf cfg.enable {
    hardware.flipperzero.enable = true;
  };
}
