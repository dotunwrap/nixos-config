_:
{ config, lib, ... }:

let
  cfg = config.bundles.base;
in

{
  options.bundles.base = {
    enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
  };

  config = lib.mkIf cfg.enable {
    programs = {
      bat.enable = true;
      btop.enable = true;
      direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      git.enable = true;
      gpg.enable = true;
      home-manager.enable = true;
      jq.enable = true;
      killall.enable = true;
      p7zip.enable = true;
      pulsemixer.enable = true;
      starship.enable = true;
      wget.enable = true;
      yazi.enable = true;
      zip.enable = true;
      zsh.enable = true;
    };
  };
}
