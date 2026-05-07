_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.eigenwallet;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.eigenwallet ];
  };
}
