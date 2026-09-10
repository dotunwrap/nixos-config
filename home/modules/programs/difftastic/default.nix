_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.difftastic;
in
{
  config = lib.mkIf cfg.enable {
    programs.difftastic = {
      git.enable = lib.mkDefault true;
    };
  };
}
