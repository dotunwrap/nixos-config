_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.proton-authenticator;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.proton-authenticator ];
  };
}
