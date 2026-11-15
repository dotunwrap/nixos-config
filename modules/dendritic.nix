{ inputs, ... }:
{
  flake-file.inputs = {
    # NOTE: overrides denful/flake-file's modules/dendritic/nixpkgs.nix mkDefault.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NOTE: must be declared here; den's own mkDefault only takes effect
    # once `inputs.den` already resolves, which needs this first.
    den.url = "github:denful/den";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    (inputs.den.flakeModules.dendritic or { })
  ];

  # NOTE: overrides denful/flake-file's modules/dendritic/systems.nix mkDefault
  systems = [ "x86_64-linux" ];
}
