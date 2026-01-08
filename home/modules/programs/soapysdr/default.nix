_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.soapysdr;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.soapysdr ];
  };
}
