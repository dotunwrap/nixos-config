_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.display-managers.lemurs;
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager.lemurs = {
      enable = true;
    };
  };
}
