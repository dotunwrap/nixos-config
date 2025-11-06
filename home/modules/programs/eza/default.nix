_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.eza;
in
{
  config = lib.mkIf cfg.enable {
    programs.eza = {
      enableZshIntegration = lib.mkIf config.programs.zsh.enable true;
      # NOTE: The nushell integration is best configured directly in nushell
      # We want to preserve the original ls and ll functionality for tables
      # enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
      git = lib.mkIf config.programs.git.enable true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
      ];
      theme = builtins.fromJSON (builtins.readFile ./themes/gruvbox-dark.json);
    };
  };
}
