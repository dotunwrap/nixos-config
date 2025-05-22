{ lib, config, ... }:
let
  cfg = config.myUser;
in
{
  programs.eza = {
    enable = true;
  };

  programs.zsh.shellAliases = lib.mkIf cfg.zsh.enable {
    ls = "eza --icons --group-directories-first";
  };
}
