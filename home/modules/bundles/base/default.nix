{
  monolisa,
  nvim,
  ...
}:
{ config, lib, ... }:

let
  cfg = config.bundles.base;
in

{
  options.bundles.base = {
    enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
  };

  config = lib.mkIf cfg.enable {
    home.packages = [
      monolisa.packages.x86_64-linux.default
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
      neovim = {
        enable = true;
        package = nvim.packages.x86_64-linux.default;
      };
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
