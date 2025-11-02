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
      enableNushellIntegration = lib.mkIf config.programs.nushell.enable true;
      git = lib.mkIf config.programs.git.enable true;
      icons = "auto";
      extraOptions = [
        "--group-directories-first"
      ];
    };
  };
}
