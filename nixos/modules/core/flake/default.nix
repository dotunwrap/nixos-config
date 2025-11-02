{
  nix,
  nixpkgs,
  programs-db,
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
    programs.command-not-found.dbPath = programs-db.packages.${pkgs.system}.programs-sqlite;

    nix = {
      package = lib.mkDefault nix.packages.${pkgs.system}.nix-cli;

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
