{ lib, ... }:
let
  inherit (lib) mkOption types;

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

  catppuccinAccentMap = {
    rosewater = "base06";
    lavender = "base07";
    red = "base08";
    peach = "base09";
    yellow = "base0A";
    green = "base0B";
    teal = "base0C";
    blue = "base0D";
    mauve = "base0E";
    flamingo = "base0F";
  };

  # A new family (e.g. gruvbox) needs only an entry here plus registry rows
  # in `schemes` below -- `den.batteries.theme` itself never changes.
  families = {
    catppuccin =
      {
        flavor,
        accent,
        subaccent,
        ...
      }:
      {
        config,
        pkgs,
        lib,
        ...
      }:
      let
        accentKey = catppuccinAccentMap.${accent};
      in
      {
        stylix = {
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-${flavor}.yaml";
          override = lib.mkIf (accent != "blue") (
            let
              rawColors = config.stylix.base16.mkSchemeAttrs config.stylix.base16Scheme;
            in
            {
              base0D = rawColors.${accentKey};
              ${accentKey} = rawColors.base0D;
            }
          );
          cursor = {
            size = 24;
            package = pkgs.catppuccin-cursors."${flavor}${titleCase accent}";
            name = "catppuccin-${flavor}-${accent}-cursors";
          };
        };

        programs.freetube.settings = lib.mkIf config.programs.freetube.enable {
          baseTheme = "catppuccin${titleCase flavor}";
          mainColor = "Catppuccin${titleCase flavor}${titleCase accent}";
          secColor = "Catppuccin${titleCase flavor}${titleCase subaccent}";
          sponsorBlockSponsor.color = "Catppuccin${titleCase flavor}Green";
          sponsorBlockSelfPromo.color = "Catppuccin${titleCase flavor}Yellow";
        };
      };

    everforest =
      { flavor, polarity, ... }:
      { pkgs, ... }:
      {
        stylix.base16Scheme =
          if polarity == "dark" then
            "${pkgs.base16-schemes}/share/themes/everforest-dark-${flavor}.yaml"
          else
            # NOTE: light variants haven't been upstreamed for every flavor --
            # only "medium" has one here (./everforest-light-medium.yaml).
            ./everforest-light-${flavor}.yaml;
      };
  };

  # A key with no entry here falls through to whatever `stylix.base16Scheme`
  # is already configured as (no override). Deliberately a plain attrset of
  # the submodule type below, not a NixOS option, so it stays evaluable from
  # inside a battery function.
  schemeType = types.submodule {
    options = {
      family = mkOption {
        type = types.enum (builtins.attrNames families);
        description = "Which family builder renders this scheme (see `families` above).";
      };
      flavor = mkOption {
        type = types.str;
        description = "Family-specific variant name, e.g. \"mocha\" or \"medium\".";
      };
      polarity = mkOption {
        type = types.enum [
          "dark"
          "light"
        ];
        default = "dark";
      };
      accent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Catppuccin-family only; ignored by other families.";
      };
      subaccent = mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "Catppuccin-family only; ignored by other families.";
      };
    };
  };

  schemes = lib.evalModules {
    modules = [
      {
        options.schemes = mkOption {
          type = types.attrsOf schemeType;
          default = {
            catppuccin-mocha = {
              family = "catppuccin";
              flavor = "mocha";
              polarity = "dark";
              accent = "mauve";
              subaccent = "lavender";
            };
            catppuccin-latte = {
              family = "catppuccin";
              flavor = "latte";
              polarity = "light";
              accent = "mauve";
              subaccent = "lavender";
            };
            everforest-dark-medium = {
              family = "everforest";
              flavor = "medium";
              polarity = "dark";
            };
            everforest-dark-hard = {
              family = "everforest";
              flavor = "hard";
              polarity = "dark";
            };
            everforest-light-medium = {
              family = "everforest";
              flavor = "medium";
              polarity = "light";
            };
          };
        };
      }
    ];
  };
in
{
  # One battery for every colorscheme. `scheme` is a registry key;
  # `accent`/`subaccent` override the registry row's defaults when given:
  #   (den.batteries.theme { hosts = [ "kaiousei" ]; scheme = "catppuccin-mocha"; })
  den.batteries.theme =
    {
      hosts,
      scheme,
      accent ? null,
      subaccent ? null,
    }:
    { host, ... }:
    {
      name = "theme(${host.name})";
    }
    // lib.optionalAttrs (builtins.elem host.name hosts) {
      homeManager =
        {
          config,
          pkgs,
          lib,
          ...
        }@args:
        lib.optionalAttrs (schemes.config.schemes ? ${scheme}) (
          let
            row = schemes.config.schemes.${scheme};
          in
          families.${row.family} (
            row
            // {
              accent = if accent != null then accent else row.accent;
              subaccent = if subaccent != null then subaccent else row.subaccent;
            }
          ) args
        );
    };
}
