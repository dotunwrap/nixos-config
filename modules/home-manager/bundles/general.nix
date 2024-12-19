{ pkgs, lib, ... }:

{
  nixpkgs = {
    config = {
      experimental-features = "nix-command flakes";
    };
  };

  myUser = {
    zsh.enable = lib.mkDefault true;
    starship.enable = lib.mkDefault true;
    git.enable = true;
    btop.enable = true;
    macchina.enable = true;
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    killall
    imagemagick
    libqalculate
    zip
    unzip
    p7zip
    wget
    yt-dlp
    tree-sitter
  ];
}
