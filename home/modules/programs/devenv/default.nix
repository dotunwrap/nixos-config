_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.devenv;
  yamlFormat = pkgs.formats.yaml { };
in
{
  config = lib.mkIf cfg.enable {
    xdg.configFile."devenv/config.yaml".source = yamlFormat.generate "config.yaml" {
      # yaml-language-server: $schema=https://devenv.sh/devenv.user.schema.json

      version = 1;

      shell.prompt_prefix = false;
    };
  };
}
