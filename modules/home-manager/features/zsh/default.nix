{ lib, config, ... }: let
  cfg = config.myUser;
in {
  programs.zsh = {
    enable = true;

    autocd = lib.mkDefault true;
    defaultKeymap = lib.mkDefault "vicmd";

    shellAliases = {
      ll = "ls -al";
      vi = "nvim";
    };

    autosuggestion.enable = lib.mkDefault true;
    syntaxHighlighting.enable = lib.mkDefault true;
  };

  programs.starship.enableZshIntegration = lib.mkIf cfg.starship.enable true;
}
