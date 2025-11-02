_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.yazi;
in
{
  config = lib.mkIf cfg.enable {
    # programs.yazi = {};
  };
}
