{
  monolisa,
  ...
}:
{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.bundles.base;
  inherit (pkgs.stdenv.hostPlatform) system;
in

{
  options.bundles.base = {
    enable = lib.mkEnableOption "The base bundle. Should always be enabled.";
    monolisaVersion = lib.mkOption { default = monolisa.packages.${system}.default; };
  };

  config = lib.mkIf cfg.enable {
    # NOTE: not `nixpkgs.config.allowUnfree` here -- forbidden under
    # `home-manager.useGlobalPkgs` (now on for every NixOS-integrated profile),
    # and redundant anyway: the NixOS-side `base` bundle already sets it on the
    # one shared `pkgs` instance every profile now uses.
    home.packages = [
      config.bundles.base.monolisaVersion
    ];

    xdg.userDirs = {
      enable = true;
      createDirectories = true;
      desktop = null;
      templates = null;
      publicShare = null;
      music = null;
      videos = null;
      setSessionVariables = true;
    };

    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        monospace = lib.mkDefault [ "MonoLisa Variable" ];
      };
    };

    programs = {
      bat.enable = true;
      brightnessctl.enable = true;
      btop.enable = true;
      cryptsetup.enable = true;
      direnv.enable = true;
      eza.enable = true;
      fzf.enable = true;
      git.enable = true;
      gh.enable = true;
      gpg.enable = true;
      home-manager.enable = true;
      jq.enable = true;
      just_.enable = true;
      killall.enable = true;
      macchina.enable = true;
      magic-wormhole.enable = true;
      mat2.enable = true;
      nix-auth.enable = true;
      nix-index.enable = true;
      nvim.enable = true;
      p7zip.enable = true;
      pulsemixer.enable = true;
      qalculate.enable = true;
      ripgrep.enable = true;
      starship.enable = true;
      pay-respects.enable = true;
      wget.enable = true;
      xsel.enable = true;
      yazi.enable = true;
      zip.enable = true;
      zsh.enable = true;
    };

    services = {
      mpris-proxy.enable = true;
      udiskie.enable = true;
    };

    home.sessionVariables = {
      EDITOR = "nvim";
    };
  };
}
