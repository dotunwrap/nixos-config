_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.p7zip;
in
{
  config = lib.mkIf cfg.enable {
    home.packages = with pkgs; [
      p7zip
    ];
  };
}
