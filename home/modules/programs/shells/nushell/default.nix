_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.nushell;
in
{
  config = lib.mkIf cfg.enable {
    programs.nushell = {
      shellAliases = {
        ols = "ls";
        oll = "ls -la";
      };
    };
  };
}
