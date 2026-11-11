{ den, ... }:
{
  den.aspects.gaming = {
    includes = [ den.aspects.rgb-lighting ];

    nixos =
      { pkgs, lib, ... }:
      {
        programs.steam = {
          enable = true;
          extraCompatPackages = lib.mkDefault [ pkgs.proton-ge-bin ];
        };
        environment.systemPackages = [ pkgs.protonup-ng ];
      };

    provides.to-users.homeManager =
      { pkgs, ... }:
      {
        home.packages = [
          pkgs.steamcmd
          pkgs.steam-tui
          pkgs.mcrcon
          pkgs.wowup-cf
        ];
        programs.prismlauncher.enable = true;
      };
  };
}
