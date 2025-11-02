_:
{
  config,
  lib,
  ...
}:
let
  bundleEnabler =
    let
      reducer = l: r: { "${r}".enable = true; } // l;
    in
    builtins.foldl' reducer { } config.activeBundles;
in
{
  options.activeBundles = lib.mkOption {
    type = lib.types.listOf lib.types.str;
    default = [ ];
  };

  config.bundles = bundleEnabler;
}
