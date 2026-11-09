{
  nixpkgs,
  ...
}:
{
  config,
  pkgs,
  lib,
  ...
}:
let
  base = "/etc/nixpkgs/channels";
  nixpkgsPath = "${base}/nixpkgs";
in
{
  options.nix.flakes.enable = lib.mkEnableOption "Enable nix flakes";

  config = lib.mkIf config.nix.flakes.enable {
    nix = {
      package = lib.mkDefault pkgs.nix;

      settings.experimental-features = [
        "nix-command"
        "flakes"
      ];

      registry.nixpkgs.flake = nixpkgs;

      nixPath = [
        "nixpkgs=${nixpkgsPath}"
        "/nix/var/nix/profiles/per-user/root/channels"
      ];
    };

    systemd.tmpfiles.rules = [
      "L+ ${nixpkgsPath}     - - - - ${nixpkgs}"
    ];
  };
}
