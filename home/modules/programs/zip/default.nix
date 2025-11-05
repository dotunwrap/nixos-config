_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.zip;
in
{
  config = lib.mkIf cfg.enable {
    # NOTE: Implicitly adding unzip here too...
    # Who wants zip without unzip??
    home.packages = with pkgs; [
      zip
      unzip
    ];
  };
}
