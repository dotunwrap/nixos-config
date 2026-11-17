{ den, ... }:
{
  den.aspects.kaiousei = {
    includes = [
      den.aspects.niri
      den.aspects.development
      den.aspects.framework-amd-ai-300
    ];

    nixos =
      { ... }:
      {
        imports = [ ./_hardware/kaiousei.nix ];

        hardware.framework.enableKmod = true;
      };

    # NOTE: theme+wallpaper is each user's own choice now
    # (modules/users/gabby/default.nix), not set here.

    provides.to-users.homeManager = _: {
      # WARNING: "HDMI-A-1" is a placeholder. Confirm the real connector
      # name via `niri msg outputs` while docked to the Odyssey G9 G95SC
      # and update this key. The HDMI link can't drive the monitor's full
      # 5120x1440 bandwidth, so "auto" in practice likely means clamshell
      # mode when docked.
      programs.niri.settings.outputs."HDMI-A-1" = {
        # NOTE: null is niri's actual "auto" spelling for `mode` (picks a
        # mode automatically) — the option type is `null or (submodule)`,
        # not a string, so don't "simplify" this to "auto".
        mode = null;
      };
    };
  };
}
