_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.nord;
in
{
  config = lib.mkIf cfg.enable {
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/nord${
      lib.optionalString (config.stylix.polarity != "dark") "-${config.stylix.polarity}"
    }.yaml";
  };
}
