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
    };
  };
}
