_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.gpg;
in
{
  config = lib.mkIf cfg.enable {
    # programs.gpg = {};
  };
}
