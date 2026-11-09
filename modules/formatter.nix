{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      formatter = import "${self}/treefmt.nix" { inherit pkgs; };

      checks.treefmt = (import "${self}/treefmt.nix" { inherit pkgs; }).check self;
    };
}
