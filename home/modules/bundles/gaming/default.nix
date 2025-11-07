_:
{ config, lib, ... }:

let
  cfg = config.bundles.gaming;
in

{
  options.bundles.gaming = {
    enable = lib.mkEnableOption "The gaming bundle.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      # NOTE: Steam itself is installed at the NixOS level
      # I fucking hate this, but it makes life easier
      # https://github.com/NixOS/nixpkgs/blob/7241bcbb4f099a66aafca120d37c65e8dda32717/nixos/modules/programs/steam.nix
      steam-tui.enable = true;
    };
  };
}
