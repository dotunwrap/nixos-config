_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.qutebrowser;
in
{
  config = lib.mkIf cfg.enable {
    # programs.qutebrowser = {};
  };
}
