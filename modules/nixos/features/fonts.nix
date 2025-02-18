{ pkgs, ... }:

{
  fonts.packages = with pkgs; [
    corefonts

    noto-fonts
    noto-fonts-cjk-sans
    noto-fonts-emoji

    garamond-libre

    nerd-fonts.jetbrains-mono
    nerd-fonts.iosevka
    nerd-fonts.fira-code
  ];
}
