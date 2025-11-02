_:
{
  lib,
  ...
}:

with lib;

{
  options.programs = {
    dmenu.enable = mkEnableOption "Enable dmenu";
    gimp.enable = mkEnableOption "Enable gimp";
    # NOTE: This cannot be `just` as hm deprecated their own `just.enable` option
    just_.enable = mkEnableOption "Enable just";
    killall.enable = mkEnableOption "Enable killall";
    lxsession.enable = mkEnableOption "Enable lxsession";
    obs.enable = mkEnableOption "Enable obs";
    p7zip.enable = mkEnableOption "Enable p7zip";
    pavucontrol.enable = mkEnableOption "Enable pavucontrol";
    pulsemixer.enable = mkEnableOption "Enable pulsemixer";
    slack.enable = mkEnableOption "Enable slack";
    st.enable = mkEnableOption "Enable st";
    wget.enable = mkEnableOption "Enable wget";
    zip.enable = mkEnableOption "Enable zip";
  };
}
