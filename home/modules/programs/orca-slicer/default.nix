_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.orca-slicer;
in
{
  config = lib.mkIf cfg.enable {
    # Native Wayland double-applies the output scale to wx bitmaps (huge
    # icons on HiDPI), so force XWayland. symlinkJoin avoids a rebuild.
    home.packages = [
      (pkgs.symlinkJoin {
        name = "orca-slicer-x11";
        paths = [ pkgs.orca-slicer ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/orca-slicer --set GDK_BACKEND x11
        '';
      })
    ];
  };
}
