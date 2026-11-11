{ lib, ... }:
{
  # Formerly home/modules/themes/everforest, then modules/users/_themes.nix's
  # `everforest` function -- the shared stylix dispatch (enable/polarity/
  # fonts/cursor-defaults/dwm-vs-niri targets) lives in modules/defaults.nix;
  # this only sets the theme-specific base16 scheme. Wallpaper is its own
  # battery (./wallpaper.nix), since the two vary independently.
  #
  # Like wallpaper, a user's theme varies by host, so this takes the list of
  # hosts it applies to rather than applying unconditionally everywhere the
  # including user/host is resolved:
  #
  #   den.aspects.gabby.includes = [ (den.batteries.everforest { hosts = [ "chikyuu" ]; }) ];
  #
  # NOTE: must be reached via `includes`, not `provides.<hostname>.<class>`
  # -- see ./wallpaper.nix's NOTE for why.
  den.batteries.everforest =
    {
      hosts,
      flavor ? "medium",
      polarity ? "dark",
    }:
    { host, ... }:
    {
      name = "everforest(${host.name})";
    }
    // lib.optionalAttrs (builtins.elem host.name hosts) {
      homeManager =
        { pkgs, ... }:
        {
          stylix.base16Scheme =
            if polarity == "dark" then
              "${pkgs.base16-schemes}/share/themes/everforest-dark-${flavor}.yaml"
            else
              # NOTE: light variants haven't been upstreamed for every flavor
              # -- only "medium" has one here (./everforest-light-medium.yaml).
              ./everforest-light-${flavor}.yaml;
        };
    };
}
