_:
{ config, lib, ... }:
let
  cfg = config.services.swayosd;
  colors = config.lib.stylix.colors;
in
{
  config = lib.mkIf cfg.enable {
    services.swayosd = { };

    xdg.configFile."swayosd/style.css".text = lib.mkDefault ''
      window#osd {
        border-radius: 8px;
        border: 1px solid ${colors.surface1};
        background: alpha(${colors.base}, 0.94);
        padding: 4px;
      }

      window#osd #container {
        margin: 16px;
      }

      window#osd image,
      window#osd label {
        color: ${colors.text};
      }

      window#osd progressbar:disabled,
      window#osd image:disabled {
        opacity: 0.5;
      }

      window#osd progressbar {
        min-height: 6px;
        border-radius: 0;
        background: transparent;
        border: none;
      }

      window#osd trough {
        min-height: 6px;
        border-radius: 0;
        border: none;
        background: ${colors.surface2};
      }

      window#osd progress {
        min-height: 6px;
        border-radius: 0;
        border: none;
        background: ${colors.mauve};
      }
    '';
  };
}
