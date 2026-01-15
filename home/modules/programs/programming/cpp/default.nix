_:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.programming.cpp;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      clang
      clang-tools
    ];
  };
}
