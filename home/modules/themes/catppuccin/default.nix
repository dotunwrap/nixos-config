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
  accentMap = {
    "rosewater" = "base06";
    "lavender" = "base07";
    "red" = "base08";
    "peach" = "base09";
    "yellow" = "base0A";
    "green" = "base0B";
    "teal" = "base0C";
    "blue" = "base0D";
    "mauve" = "base0E";
    "flamingo" = "base0F";
  };
  accentKey = a: accentMap.${a};
  titleCase =
    str:
    lib.concatStringsSep " " (
      map (
        word:
        if word == "" then
          ""
        else
          lib.toUpper (builtins.substring 0 1 word) + builtins.substring 1 (builtins.stringLength word) word
      ) (lib.splitString " " str)
    );
in
{
  options.themes.catppuccin = {
    flavor = lib.mkOption {
      type = lib.types.enum [
        "mocha"
        "macchiato"
        "frappe"
        "latte"
      ];
      default = "mocha";
      description = "The flavor of Catppuccin to use.";
    };

    accent = lib.mkOption {
      type = lib.types.enum (builtins.attrNames accentMap);
      default = "blue";
      description = "The main accent color to use.";
    };

    subaccent = lib.mkOption {
      type = lib.types.enum (builtins.attrNames accentMap);
      default = "sky";
      description = "The secondary accent color to use.";
    };
  };

  config = lib.mkIf cfg.enable {
    stylix.base16Scheme = "${pkgs.base16-schemes}/share/themes/${fileName}.yaml";
    stylix.override = lib.mkIf (cfg.accent != "blue") (
      let
        rawColors = config.stylix.base16.mkSchemeAttrs config.stylix.base16Scheme;
      in
      {
        base0D = rawColors.${accentKey cfg.accent};
        ${accentKey cfg.accent} = rawColors.base0D;
      }
    );
    programs.freetube.settings =
      lib.mkIf (config.programs.freetube.enable && cfg.flavor != "macchiato")
        {
          baseTheme = "catppuccin${titleCase cfg.flavor}";
          mainColor = "Catppuccin${titleCase cfg.flavor}${titleCase cfg.accent}";
          secColor = "Catppuccin${titleCase cfg.flavor}${titleCase cfg.subaccent}";
          sponsorBlockSponsor.color = "Catppuccin${titleCase cfg.flavor}Green";
          sponsorBlockSelfPromo.color = "Catppuccin${titleCase cfg.flavor}Yellow";
        };
  };
}
