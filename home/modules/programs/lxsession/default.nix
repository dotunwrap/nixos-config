_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.lxsession;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ lxsession ];
  };
}
