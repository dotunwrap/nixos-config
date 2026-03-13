_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.dracula;
in
{
  config = lib.mkIf cfg.enable {
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/dracula.yaml";
  };
}
