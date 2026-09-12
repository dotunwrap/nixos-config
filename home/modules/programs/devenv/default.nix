_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.devenv_;
  yamlFormat = pkgs.formats.yaml { };
in
{
  config = lib.mkIf cfg.enable {
    # NOTE: Install from nixpkgs instead of using hm's native `programs.devenv` module
    #       as the module has been out of date for months.
    home.packages = with pkgs; [ devenv ];

    xdg.configFile."devenv/config.yaml".source = yamlFormat.generate "config.yaml" {
      # yaml-language-server: $schema=https://devenv.sh/devenv.user.schema.json

      version = 1;

      shell.prompt_prefix = false;
    };
  };
}
