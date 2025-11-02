_: {
  perSystem =
    {
      config,
      pkgs,
      inputs',
      self',
      system,
      ...
    }:
    {
      formatter = pkgs.nixfmt;

      devShells.default = pkgs.mkShell {
        packages = builtins.attrValues {
          inherit (pkgs) sops nil nixfmt;
        };
      };
    };
}
