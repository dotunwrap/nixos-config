_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.slack;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ slack ];
  };
}
