_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.bambu-studio;
in
{
  config = lib.mkIf cfg.enable {
    # Native Wayland double-applies the output scale to wx bitmaps (huge
    # icons on HiDPI), so force XWayland. symlinkJoin avoids a rebuild.
    home.packages = [
      (pkgs.symlinkJoin {
        name = "bambu-studio-x11";
        paths = [ pkgs.bambu-studio ];
        nativeBuildInputs = [ pkgs.makeWrapper ];
        postBuild = ''
          wrapProgram $out/bin/bambu-studio --set GDK_BACKEND x11
        '';
      })
    ];
  };
}
