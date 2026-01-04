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
        c.enable = lib.mkDefault true;
        go.enable = lib.mkDefault true;
        javascript.enable = lib.mkDefault true;
        rust.enable = lib.mkDefault true;
        typst.enable = lib.mkDefault true;
        zig.enable = lib.mkDefault true;
      };
    };
  };
}
