{ den, ... }:
{
  den.aspects.kaiousei = {
    includes = [
      den.aspects.niri
      den.aspects.development
      den.aspects.framework-amd-ai-300
    ];

    nixos =
      { ... }:
      {
        imports = [ ./_hardware/kaiousei.nix ];

        hardware.framework.enableKmod = true;
      };

    # NOTE: theme+wallpaper is each user's own choice now (see
    # modules/users/gabby/default.nix) -- not set here.
  };
}
