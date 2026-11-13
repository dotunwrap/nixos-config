{ lib, ... }:
{
  # Independent of theme (./theme.nix) -- same theme, different image is a
  # real combination. One call per host, each with its own `host`/`path`
  # pair rather than a shared hostname -> path map:
  #   (den.batteries.wallpaper { host = "chikyuu"; path = ./foo.png; })
  #
  # Must be reached via `includes`, not `provides.<hostname>.<class>` --
  # `den.batteries` isn't resolvable from inside a `provides` value (evaluated
  # before batteries are merged into the fixpoint `den` arg).
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
