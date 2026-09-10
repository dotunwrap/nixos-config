_:
{
  config,
  lib,
  pkgs,
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
    xdg.userDirs.extraConfig.CODE = "${config.home.homeDirectory}/Code";

    programs = {
      claude-code.enable = true;
      devenv.enable = true;
      difftastic.enable = true;
      httpie.enable = true;
      omnix.enable = true;
      programming = {
        cpp.enable = lib.mkDefault true;
        go.enable = lib.mkDefault true;
        javascript.enable = lib.mkDefault true;
        rust.enable = lib.mkDefault true;
        typst.enable = lib.mkDefault true;
        zig.enable = lib.mkDefault true;
      };
      secretspec.enable = true;
    };
  };
}
