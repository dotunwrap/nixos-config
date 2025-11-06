_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.display-managers.ly;
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager.ly = {
      enable = true;
      package = pkgs.ly;
      settings = {
        animation = "gameoflife";
        bigclock = "en";
        clear_password = true;
        default_input = "password";
      };
    };
  };
}
