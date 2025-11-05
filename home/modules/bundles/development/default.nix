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
    xdg.userDirs.extraConfig.XDG_CODE_DIR = "${config.home.homeDirectory}/Code";

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
