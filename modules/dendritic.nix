{ inputs, ... }:
{
  imports = [ inputs.flake-file.flakeModules.dendritic ];

  # NOTE: overrides denful/flake-file's modules/dendritic/systems.nix mkDefault
  systems = [ "x86_64-linux" ];
}
