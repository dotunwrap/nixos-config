{
  pkgs,
  config,
  ...
}: {
  nixpkgs = {
    config = {
      experimental-features = "nix-command flakes";
    };
  };

  myUser = {
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
