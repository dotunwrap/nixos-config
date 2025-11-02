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
      formatter = pkgs.nixfmt-tree;

      devShells.default = pkgs.mkShell {
        packages = builtins.attrValues {
          inherit (pkgs)
            sops
            nil
            nixfmt-tree
            nixfmt
            ;
        };
      };
    };
}
