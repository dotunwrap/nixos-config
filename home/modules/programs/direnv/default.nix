_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.direnv;
in
{
  config = lib.mkIf cfg.enable {
    programs.direnv = {
      nix-direnv.enable = lib.mkDefault true;
      silent = lib.mkDefault true;
      config.global.hide_env_diff = lib.mkDefault true;
    };
  };
}
