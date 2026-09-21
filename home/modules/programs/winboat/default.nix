_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.winboat;
in
{
  config = lib.mkIf cfg.enable {
    # Rootless podman as winboat's container runtime; winboat checks for
    # `podman compose` with the podman-compose provider.
    services.podman.enable = true;

    home.packages = with pkgs; [
      winboat
      podman-compose
    ];
  };
}
