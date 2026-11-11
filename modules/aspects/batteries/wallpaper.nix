{ lib, ... }:
{
  # A theme (everforest/catppuccin, see ./everforest.nix, ./catppuccin.nix)
  # and a wallpaper are independent choices -- same theme, different image,
  # is a real combination a user might want, so each gets its own battery
  # rather than one function taking both.
  #
  # Unlike primary-user/user-shell (which apply identically to every host a
  # user includes them from), a user's wallpaper differs per host -- so this
  # takes a hostname -> image map and, per host it's resolved for, applies
  # only the entry matching that host:
  #
  #   den.aspects.gabby.includes = [
  #     (den.batteries.wallpaper { chikyuu = ./foo.png; kaiousei = ./bar.png; })
  #   ];
  #
  # NOTE: must be reached via `includes`, not `provides.<hostname>.<class>`
  # -- `den.batteries` isn't resolvable from inside a `provides` value
  # (evaluated before batteries are merged into the fixpoint `den` arg).
  den.batteries.wallpaper =
    images:
    { host, ... }:
    {
      name = "wallpaper(${host.name})";
    }
    // lib.optionalAttrs (builtins.hasAttr host.name images) {
      homeManager = _: { stylix.image = images.${host.name}; };
    };
}
