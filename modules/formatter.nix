{ self, ... }:
let
  treefmt = import ./_data/treefmt.nix;
in
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = treefmt { inherit pkgs; };

      checks.treefmt = (treefmt { inherit pkgs; }).check self;
    };
}
