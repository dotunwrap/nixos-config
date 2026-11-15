{ lib, ... }:
{
  # NOTE: independent of theme.nix; one call per host, e.g.
  #   (den.batteries.wallpaper { host = "chikyuu"; path = ./foo.png; })
  #
  # NOTE: must be reached via `includes`, not `provides`: `den.batteries`
  # isn't resolvable from a `provides` value (evaluated before the fixpoint).
  den.batteries.wallpaper =
    { host, path }:
    ctx:
    {
      name = "wallpaper(${ctx.host.name})";
    }
    // lib.optionalAttrs (ctx.host.name == host) {
      homeManager = _: {
        stylix.image = path;
      };
    };
}
