_:
{ lib, config, ... }:
let
  cfg = config.misc.niri-config;
in
{
  config = lib.mkIf cfg.enable {
    programs.niri.settings =
      let
        importDefaultSettings = f: import f { inherit lib; };
      in
      {
        input = importDefaultSettings ./input.nix;
        binds = importDefaultSettings ./binds.nix;
        layout = importDefaultSettings ./layout.nix;

        clipboard.disable-primary = lib.mkDefault true;
        prefer-no-csd = lib.mkDefault true;
        overview.zoom = lib.mkDefault 0.5;
      };
  };
}
