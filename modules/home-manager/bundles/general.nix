{
  pkgs,
  config,
  lib,
  inputs,
  ...
}: {
  nixpkgs = {
    config = {
      experimental-features = "nix-command flakes";
    };
  };

  myUser = {
  };

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    git
    # neovim
    killall
    imagemagick
    htop
    libqalculate
    zip
    unzip
    p7zip
    
    wget

    yt-dlp
    tree-sitter
  ];

  home.sessionVariables = {
    FLAKE = "${config.home.homeDirectory}/nixconf";
  };
}
