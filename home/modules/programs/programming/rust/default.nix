_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.programming.rust;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.rust-bin.stable.latest.default ];
  };
}
