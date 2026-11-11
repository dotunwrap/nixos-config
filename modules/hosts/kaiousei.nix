{ den, inputs, ... }:
{
  den.aspects.kaiousei = {
    includes = [
      den.aspects.niri
      den.aspects.development
    ];

    nixos =
      { ... }:
      {
        imports = [
          ./_hardware/kaiousei.nix
          inputs.nixos-hardware.nixosModules.framework-amd-ai-300-series
        ];

        hardware.framework.enableKmod = true;

        networking.hostName = "kaiousei";
      };

    # Formerly home/modules/themes/catppuccin (flavor=mocha, accent=mauve,
    # subaccent=lavender) + the per-profile `themes.catppuccin.*`/`stylix.image`
    # in home/configurations/gabby-at-kaiousei.nix. Host-scoped: kaiousei and
    # meiousei share this exact theme+wallpaper across their (different)
    # users, confirming it's a machine choice, not a personal one. The shared
    # stylix dispatch lives in modules/defaults.nix; this is the
    # catppuccin-specific part, with the flavor/accent/subaccent already
    # resolved to constants (no per-host dynamic option needed since each
    # host's choice doesn't change).
    provides.to-users.homeManager =
      {
        config,
        pkgs,
        lib,
        ...
      }:
      {
        stylix = {
          image = ../../assets/wallpapers/anyb-girl.png;
          base16Scheme = "${pkgs.base16-schemes}/share/themes/catppuccin-mocha.yaml";
          # accent "mauve" (base0E) != stylix's own default accent (base0D):
          # swap the two so stylix's accent-driven targets pick up mauve.
          override =
            let
              rawColors = config.stylix.base16.mkSchemeAttrs config.stylix.base16Scheme;
            in
            {
              base0D = rawColors.base0E;
              base0E = rawColors.base0D;
            };
          cursor = {
            size = 24;
            package = pkgs.catppuccin-cursors.mochaMauve;
            name = "catppuccin-mocha-mauve-cursors";
          };
        };

        programs.freetube.settings = lib.mkIf config.programs.freetube.enable {
          baseTheme = "catppuccinMocha";
          mainColor = "CatppuccinMochaMauve";
          secColor = "CatppuccinMochaLavender";
          sponsorBlockSponsor.color = "CatppuccinMochaGreen";
          sponsorBlockSelfPromo.color = "CatppuccinMochaYellow";
        };
      };
  };
}
