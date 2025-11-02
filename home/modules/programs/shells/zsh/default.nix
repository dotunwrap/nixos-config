_:
{ config, lib, ... }:
let
  cfg = config.programs.zsh;
in
{
  config = lib.mkIf cfg.enable {
    imports = [
      ./aliases.nix
      ./functions.nix
    ];

    programs.zsh = {
      autocd = lib.mkDefault true;
      defaultKeymap = lib.mkDefault "vicmd";
      autosuggestion.enable = lib.mkDefault true;
      syntaxHighlighting.enable = lib.mkDefault true;
    };
  };
}
