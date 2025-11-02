_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.wget;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      wget
    ];
  };
}
