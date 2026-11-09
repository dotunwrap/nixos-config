{ self, ... }:
{
  perSystem =
    { pkgs, ... }:
    {
      devShells.default = pkgs.mkShell {
        packages = import "${self}/shell-pkgs.nix" { inherit pkgs; };
      };
    };
}
