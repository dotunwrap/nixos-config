_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.opencode;
in
{
  config = lib.mkIf cfg.enable {
    # programs.opencode = {};
  };
}
