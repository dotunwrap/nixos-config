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
    # NOTE: This silences an eval warning for Yazi on systems with home.stateVersion being less than 26.05
    programs.yazi.shellWrapperName = "y";
  };
}
