_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.nix;
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

  config = lib.mkIf cfg.enable (
    lib.mkMerge [
      (lib.mkIf (allowed != [ ]) {
        nixpkgs.config.allowUnfreePredicate = pkg: builtins.elem (lib.getName pkg) allowed;
      })
      { nix.settings.auto-optimise-store = lib.mkDefault true; }
      {
        nix.settings = {
          trusted-users = lib.mkDefault [
            "root"
            "@wheel"
          ];
          min-free = lib.mkDefault (5 * (1024 * 1024 * 1024));
          max-free = lib.mkDefault (25 * (1024 * 1024 * 1024));
          allow-import-from-derivation = lib.mkDefault false;
        };
      }
    ]
  );
}
