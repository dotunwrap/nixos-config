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
      };

    # Theme+wallpaper is each user's own choice now (see
    # modules/users/gabby.nix) -- not set here.
  };
}
