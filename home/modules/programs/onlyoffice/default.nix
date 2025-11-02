_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.onlyoffice;
in
{
  config = lib.mkIf cfg.enable {
    # programs.onlyoffice = {};
  };
}
