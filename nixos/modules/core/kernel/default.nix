_:
{
  pkgs,
  lib,
  config,
  ...
}:
let
  cfg = config.core.kernel;
  supportedFilesystems =
    if builtins.isList config.boot.supportedFilesystems then
      config.boot.supportedFilesystems ++ config.boot.initrd.supportedFilesystems
    else
      builtins.attrNames (
        lib.filterAttrs (_name: value: value) (
          config.boot.supportedFilesystems // config.boot.initrd.supportedFilesystems
        )
      );
  zfsUsed = lib.lists.elem "zfs" supportedFilesystems;
in
{
  config = lib.mkIf cfg.enable {
    boot.kernelPackages = lib.mkDefault (
      if zfsUsed then pkgs.zfs.latestCompatibleLinuxPackages else pkgs.linuxPackages_latest
    );
  };
}
