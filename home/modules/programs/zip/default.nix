_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zip;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ zip ];
  };
}
