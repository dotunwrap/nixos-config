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
      treefmt = import "${self}/treefmt.nix" { inherit pkgs; };
    in
    {
      formatter = treefmt;

      devShells.default = pkgs.mkShell {
        packages = builtins.attrValues {
          inherit (pkgs) sops nil;
          inherit treefmt;
        };
      };
    };
}
