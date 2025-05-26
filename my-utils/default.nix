{ inputs }:
let
  myUtils = (import ./default.nix) { inherit inputs; };
  inherit (inputs.self) outputs;
in
rec {
  pkgsFor = sys: inputs.nixpkgs.legacyPackages.${sys};

  mkSystem =
    config:
    inputs.nixpkgs.lib.nixosSystem {
      specialArgs = {
        inherit inputs outputs myUtils;
      };
      modules = [
        config
        outputs.nixosModules.default
      ];
    };

  mkHome =
    sys: displayServer: config:
    inputs.home-manager.lib.homeManagerConfiguration {
      pkgs = pkgsFor sys;
      extraSpecialArgs = {
        inherit
          inputs
          myUtils
          outputs
          displayServer
          ;
      };
      modules = [
        config
        outputs.homeManagerModules.default
      ];
    };

  forDisplayServer = displayServer: map: map.${displayServer};

  filesIn = dir: (map (fname: dir + "/${fname}") (builtins.attrNames (builtins.readDir dir)));

  dirsIn =
    dir: inputs.nixpkgs.lib.filterAttrs (name: value: value == "directory") (builtins.readDir dir);

  fileNameOf = path: (builtins.head (builtins.split "\\." (baseNameOf path)));

  extendModule =
    { path, ... }@args:
    { pkgs, ... }@margs:
    let
      eval = if (builtins.isString path) || (builtins.isPath path) then import path margs else path margs;
      evalNoImports = builtins.removeAttrs eval [
        "imports"
        "options"
      ];

      extra =
        if (builtins.hasAttr "extraOptions" args) || (builtins.hasAttr "extraConfig" args) then
          [
            (_: {
              options = args.extraOptions or { };
              config = args.extraConfig or { };
            })
          ]
        else
          [ ];
    in
    {
      imports = (eval.imports or [ ]) ++ extra;

      options =
        if builtins.hasAttr "optionsExtension" args then
          (args.optionsExtension (eval.options or { }))
        else
          (eval.options or { });

      config =
        if builtins.hasAttr "configExtension" args then
          (args.configExtension (eval.config or evalNoImports))
        else
          (eval.config or evalNoImports);
    };

  extendModules =
    extension: modules:
    map (
      f:
      let
        name = fileNameOf f;
      in
      extendModule (
        (extension name)
        // {
          path = f;
        }
      )
    ) modules;

  forAllSystems =
    pkgs:
    inputs.nixpkgs.lib.genAttrs [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ] (system: pkgs inputs.nixpkgs.legacyPackages.${system});
}
