_:
{ config, lib, ... }:
let
  cfg = config.programs.claude-code;
in
{
  config = lib.mkIf cfg.enable {
    programs.claude-code = {
      mcpServers = import ./mcp.nix;
    };
  };
}
