_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.gnupg;
in
{
  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      pinentry-curses
    ];

    services.pcscd.enable = true;
    programs.gnupg.agent = {
      enable = true;
      pinentryPackage = pkgs.pinentry-curses;
      enableSSHSupport = true;
    };
  };
}
