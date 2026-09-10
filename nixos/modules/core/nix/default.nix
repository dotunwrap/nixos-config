_:
{
  config,
  lib,
  ...
}:
let
  allowed = config.nix.allowedUnfree;
in
{
  options.nix = {
    allowedUnfree = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Allows for unfree packages by their name.
      '';
    };
  };

  config = lib.mkMerge [
    (lib.mkIf (allowed != [ ]) {
      nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed;
    })
    { nix.settings.auto-optimise-store = lib.mkDefault true; }
    {
      nix.settings = {
        # Plain assignment, not mkDefault: nixpkgs' own nix.nix module sets
        # trusted-users = [ "root" ] at normal priority, which otherwise wins
        # outright over a weaker mkDefault and silently drops "@wheel".
        trusted-users = [
          "root"
          "@wheel"
        ];
        min-free = lib.mkDefault (5 * (1024 * 1024 * 1024));
        max-free = lib.mkDefault (25 * (1024 * 1024 * 1024));
        allow-import-from-derivation = lib.mkDefault true;
      };
    }
    {
      nix = {
        gc = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault "daily";
          persistent = lib.mkDefault true;
          randomizedDelaySec = lib.mkDefault "45min";
        };
        optimise = {
          automatic = lib.mkDefault true;
          dates = lib.mkDefault [ "daily" ];
          persistent = lib.mkDefault true;
          randomizedDelaySec = lib.mkDefault "45min";
        };
      };
    }
  ];
}
