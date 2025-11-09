_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.zsh;
in
{
  config = lib.mkIf cfg.enable {
    programs.zsh = {
      autocd = lib.mkDefault true;
      shellAliases = { } // import ../shellAliases.nix;

      antidote = {
        enable = true;
        plugins = [
          "jeffreytse/zsh-vi-mode"

          "mattmc3/ez-compinit"

          "getantidote/use-omz"
          "ohmyzsh/ohmyzsh path:lib"
          "ohmyzsh/ohmyzsh path:plugins/colored-man-pages"
          "ohmyzsh/ohmyzsh path:plugins/direnv"
          "ohmyzsh/ohmyzsh path:plugins/sudo"

          "mattmc3/zfunctions"
          "zsh-users/zsh-autosuggestions"
          "zdharma-continuum/fast-syntax-highlighting kind:defer"
          "zsh-users/zsh-history-substring-search"
        ];
      };
    };
  };
}
