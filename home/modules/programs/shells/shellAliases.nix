{ config }:
{
  ll = "ls -la";
  c =
    if config.bundles.dwm.enable then
      "xsel --clipboard --input"
    else if config.bundles.niri.enable then
      "wl-copy"
    else
      "";
}
