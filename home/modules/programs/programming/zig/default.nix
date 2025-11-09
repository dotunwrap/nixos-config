_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.programming.zig;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [ zig ];
  };
}
