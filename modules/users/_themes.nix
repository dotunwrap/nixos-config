{
  # Formerly home/modules/themes/everforest. The shared stylix dispatch
  # (enable/polarity/fonts/cursor-defaults/dwm-vs-niri targets) lives in
  # modules/defaults.nix; each of these only sets the theme-specific part.
  everforest =
    {
      image,
      flavor ? "medium",
      polarity ? "dark",
    }:
    { pkgs, ... }:
    {
      stylix.image = image;
      stylix.base16Scheme =
        if polarity == "dark" then
          "${pkgs.base16-schemes}/share/themes/everforest-dark-${flavor}.yaml"
        else
          # NOTE: light variants haven't been upstreamed for every flavor --
          # only "medium" has one here (./everforest-light-medium.yaml).
          ./everforest-light-${flavor}.yaml;
    };

  catppuccin =
    {
      image,
      flavor ? "mocha",
      accent ? "mauve",
      subaccent ? "lavender",
    }:
    {
      config,
      pkgs,
      lib,
      ...
    }:
    let
      accentMap = {
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
      accentKey = accentMap.${accent};
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
      stylix = {
        inherit image;
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
}
