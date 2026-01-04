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
    xdg.userDirs.extraConfig.XDG_CODE_DIR = "${config.home.homeDirectory}/Code";

    programs = {
      claude-code = {
        enable = true;
        package = pkgs.claude-code;
        mcpServers = {
          deepwiki = {
            type = "http";
            url = "https://mcp.deepwiki.com/mcp";
          };
        };
      };
      httpie.enable = true;
      monero-cli.enable = true;
      opencode.enable = true;
      programming = {
        c.enable = true;
        cpp.enable = true;
        go.enable = true;
        javascript.enable = true;
        rust.enable = true;
        typst.enable = true;
        zig.enable = true;
      };
    };
  };
}
