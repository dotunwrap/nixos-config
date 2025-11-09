{
  monolisa,
  nvim,
  ...
}:
{ config, lib, pkgs, ... }:

let
  cfg = config.bundles.base;
  inherit (pkgs.stdenv.hostPlatform) system;
  nixvim-package = nvim.packages.${system}.default;
  styled-nixvim = nixvim-package.extend config.stylix.targets.nixvim.exportedModule;
in

{
  options.bundles.base = {
    enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      monolisa.packages.x86_64-linux.default
      styled-nixvim
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = null;
      templates = null;
      publicShare = null;
      music = null;
      videos = null;
    };

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = [ "MonoLisa Variable" ];
      };
    };

    programs = {
      bat.enable = true;
      brightnessctl.enable = true;
      btop.enable = true;
      direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      git.enable = true;
      gpg.enable = true;
      home-manager.enable = true;
      jq.enable = true;
      just_.enable = true;
      killall.enable = true;
      macchina.enable = true;
      magic-wormhole.enable = true;
      p7zip.enable = true;
      pulsemixer.enable = true;
      starship.enable = true;
      wget.enable = true;
      yazi.enable = true;
      zip.enable = true;
      zsh.enable = true;
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
