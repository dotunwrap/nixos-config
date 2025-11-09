_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.programming.javascript;
in
{
  config = lib.mkIf cfg.enable {
    programs = {
      bun.enable = true;
    };
  };
}
