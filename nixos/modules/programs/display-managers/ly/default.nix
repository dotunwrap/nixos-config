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
        bigclock = "en";
        clear_password = true;
        default_input = "password";
        vi_mode = true;
        box_title = "${config.networking.hostName}";
        hide_system_users = true;
      };
    };
  };
}
