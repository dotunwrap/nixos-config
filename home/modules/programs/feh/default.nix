_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.feh;
in
{
  config = lib.mkIf cfg.enable {
    # programs.feh = {};
  };
}
