_:
{ config, lib, ... }:
let
  cfg = config.programs.firefox;
in
{
  config = lib.mkIf cfg.enable {
    programs.firefox.configPath = "${config.xdg.configHome}/mozilla/firefox";
  };
}
