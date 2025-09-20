_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pulsemixer;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      pulsemixer
    ];
  };
}
