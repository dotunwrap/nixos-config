_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.window-managers.dwm;
in
{
  config = lib.mkIf cfg.enable {
    services.xserver = {
      enable = true;
      windowManager = {
        dwm = {
          enable = true;
          package = pkgs.dwm.override {
            # conf = ./config.def.h;
            patches = [
              ./patches/dwm-colorbar-6.3.diff
              ./patches/dwm-fixmultimon-6.4.diff
              ./patches/dwm-focusfullscreen-20211121-95e7342.diff
              ./patches/dwm-focusmaster-return-6.2.diff
              ./patches/dwm-focusmonmouse-6.2.diff
              ./patches/dwm-hide_vacant_tags-6.4.diff
              ./patches/dwm-preventfocusshift-20240831-6.5.diff
              ./patches/dwm-restartsig-20180523-6.2.diff
              ./patches/dwm-spawntag-6.2.diff
              ./patches/dwm-stacker-6.2.diff
              ./patches/dwm-statuscmd-20241009-8933ebc.diff
              ./patches/dwm-sticky-6.5.diff
              ./patches/dwm-swallow-6.3.diff
              ./patches/dwm-vanitygaps-6.2.diff
            ];
          };
        };
      };
    };
  };
}
