_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.git;
in
{
  config = lib.mkIf cfg.enable {
    programs.git.settings = {
      init = {
        defaultBranch = "main";
      };
    };
  };
}
