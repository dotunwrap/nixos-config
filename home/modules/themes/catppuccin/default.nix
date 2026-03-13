_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.catppuccin;
  fileName = "catppuccin-${cfg.flavor}";
in
{
  options.themes.catppuccin.flavor = lib.mkOption {
    type = lib.types.enum [
      "mocha"
      "macchiato"
      "frappe"
      "latte"
    ];
    default = "mocha";
    description = "The flavor of Catppuccin to use.";
  };

  config = lib.mkIf cfg.enable {
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${fileName}.yaml";
  };
}
