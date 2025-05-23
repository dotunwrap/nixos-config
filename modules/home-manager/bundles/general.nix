{ lib, ... }:

{
  nixpkgs = {
    config = {
      experimental-features = "nix-command flakes";
    };
  };

  myUser = {
    zsh.enable = lib.mkDefault true;
    starship.enable = lib.mkDefault true;
    eza.enable = lib.mkDefault true;
    git.enable = lib.mkDefault true;
    btop.enable = lib.mkDefault true;
    macchina.enable = lib.mkDefault true;
    killall.enable = lib.mkDefault true;
    imagemagick.enable = lib.mkDefault true;
    libqalculate.enable = lib.mkDefault true;
    zip.enable = lib.mkDefault true;
    unzip.enable = lib.mkDefault true;
    p7zip.enable = lib.mkDefault true;
    wget.enable = lib.mkDefault true;
    yt-dlp.enable = lib.mkDefault true;
    tree-sitter.enable = lib.mkDefault true;
    direnv.enable = lib.mkDefault true;
  };

  programs.home-manager.enable = true;
}
