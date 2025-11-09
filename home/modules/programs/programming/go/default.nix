_:
{ config, lib, ... }:
let
  cfg = config.programs.programming.go;
in
{
  config = lib.mkIf cfg.enable {
    programs.go = {
      enable = true;
      telemetry = {
        mode = "off";
      };
    };
  };
}
