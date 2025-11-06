_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.btop;
in
{
  config = lib.mkIf cfg.enable {
    programs.btop.settings = {
      color_theme = lib.mkDefault "gruvbox_dark";
      theme_background = lib.mkDefault false;
      vim_keys = lib.mkDefault true;
    };
  };
}
