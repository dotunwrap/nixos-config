_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.xsession.windowManager.dwm;
in
{
  options.xsession.windowManager.dwm = {

  };

  config = lib.mkIf cfg.enable { };
}
