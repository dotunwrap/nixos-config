{ inputs, ... }:
{
  flake-file.inputs = {
    # NOTE: overrides denful/flake-file's modules/dendritic/nixpkgs.nix mkDefault.
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    # NOTE: must be declared here, not left to denful/den's own dendritic.nix
    # mkDefault -- that default only takes effect once `inputs.den` already
    # resolves, which requires this declaration to exist first. Bootstrap, not
    # redundant.
    den.url = "github:denful/den";
  };

  imports = [
    inputs.flake-file.flakeModules.dendritic
    (inputs.den.flakeModules.dendritic or { })
  ];

  # NOTE: overrides denful/flake-file's modules/dendritic/systems.nix mkDefault
  systems = [ "x86_64-linux" ];
}
