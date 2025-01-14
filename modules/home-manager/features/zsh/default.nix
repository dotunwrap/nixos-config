{ lib, config, ... }: let
  cfg = config.myUser;
in {
  imports = [
    ./aliases.nix
    ./functions.nix
  ];

  programs.zsh = {
    enable = true;

    autocd = lib.mkDefault true;
    defaultKeymap = lib.mkDefault "vicmd";

    autosuggestion.enable = lib.mkDefault true;
    syntaxHighlighting.enable = lib.mkDefault true;
  };

  programs.starship.enableZshIntegration = lib.mkIf cfg.starship.enable true;
}
