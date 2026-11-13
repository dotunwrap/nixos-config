{
  # NOTE: unlike base, this is NOT a den.default -- every host and every user
  # currently wants it, but that's today's reality, not a reason to make it
  # impossible to turn off. A normal, host-included aspect (same shape as
  # gaming/dwm/niri) so any future host can simply not include it.
  den.aspects.development = {
    nixos = _: {
      hardware.flipperzero.enable = true;
    };

    provides.to-users.homeManager =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      {
        home.packages = [
          pkgs.devenv
          pkgs.httpie
          pkgs.omnix
          pkgs.clang
          pkgs.clang-tools
          pkgs.deno
          pkgs.nodejs
          pkgs.rust-bin.stable.latest.default
          pkgs.typst
          pkgs.zig
        ];

        xdg = {
          userDirs.extraConfig.CODE = "${config.home.homeDirectory}/Code";
          configFile."devenv/config.yaml".source = (pkgs.formats.yaml { }).generate "config.yaml" {
            # yaml-language-server: $schema=https://devenv.sh/devenv.user.schema.json
            version = 1;
            shell.prompt_prefix = false;
          };
        };

        programs = {
          claude-code.mcpServers = {
            deepwiki = {
              type = "http";
              url = "https://mcp.deepwiki.com/mcp";
            };
          };
          difftastic.git.enable = lib.mkDefault true;
          go = {
            enable = true;
            telemetry.mode = "off";
          };
          bun.enable = true;
        };
      };
  };
}
