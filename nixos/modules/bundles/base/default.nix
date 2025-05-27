_:
{ config, lib, ... }:

let
  cfg = config.bundles.base;
in

{
  options.bundles.base = {
    enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
    };
  };
}
