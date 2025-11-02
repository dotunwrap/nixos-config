_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    c.enable = mkEnableOption "Enable C";
    go.enable = mkEnableOption "Enable Go";
    javascript.enable = mkEnableOption "Enable JavaScript";
    rust.enable = mkEnableOption "Enable Rust";
    typst.enable = mkEnableOption "Enable Typst";
    zig.enable = mkEnableOption "Enable Zig";
  };
}
