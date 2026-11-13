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

    # Theme+wallpaper is each user's own choice now (see
    # modules/users/gabby.nix) -- not set here.
  };
}
