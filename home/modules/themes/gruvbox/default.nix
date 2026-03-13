_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.gruvbox;
  fileName =
    let
      base = "gruvbox-${config.stylix.polarity}";
      flavorSuffix = lib.optionalString (cfg.flavor != "base") "-${cfg.flavor}";
    in
    "${base}${flavorSuffix}";
in
{
  options.themes.gruvbox.flavor = lib.mkOption {
    type = lib.types.enum [
      "base"
      "hard"
      "medium"
      "soft"
    ];
    default = "base";
    description = "The flavor of Gruvbox to use.";
  };

  config = lib.mkIf cfg.enable {
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${fileName}.yaml";
  };
}
