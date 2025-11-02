_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.bundles.development;
in
{
  options.bundles.development = {
    enable = lib.mkEnableOption "The development bundle.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      opencode.enable = true;
      programming = {
        c.enable = true;
        go.enable = true;
        javascript.enable = true;
        rust.enable = true;
        typst.enable = true;
        zig.enable = true;
      };
    };
  };
}
