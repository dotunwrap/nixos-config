_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.prismlauncher;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = [ pkgs.prismlauncher ];
  };
}
