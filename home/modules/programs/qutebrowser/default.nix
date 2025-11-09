_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.qutebrowser;
in
{
  config = lib.mkIf cfg.enable {
    programs.qutebrowser = {
      greasemonkey = [
        (pkgs.fetchurl {
          url = "https://raw.githubusercontent.com/qutebrowser/qutebrowser/refs/heads/main/misc/userscripts/qute-bitwarden";
          sha256 = "sha256-oHjwIefAsjcDzVH1h+ykwFn+C0u+ALpFI2q6D6f0SiQ=";
        })
      ];
      keyBindings = {
        normal = {
          "[b" = "tab-prev";
          "]b" = "tab-next";
          "St" = lib.mkMerge [
            "config-cycle tabs.show never always"
            "config-cycle statusbar.show never always"
            "config-cycle scrolling.bar never always"
          ];
        };
      };
    };
  };
}
