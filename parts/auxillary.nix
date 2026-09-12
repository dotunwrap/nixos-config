{ self, ... }:
{
  perSystem =
    {
      config,
      pkgs,
      inputs',
      self',
      system,
      ...
    }:
    let
      inherit (pkgs) mkShell;

      treefmt = import "${self}/treefmt.nix" { inherit pkgs; };
    in
    {
      formatter = treefmt;

      devShells.default = mkShell {
        packages = import "${self}/shell-pkgs.nix" { inherit pkgs; };
      };

      checks = {
        treefmt = (import ../treefmt.nix { inherit pkgs; }).check self;
      };
    };
}
