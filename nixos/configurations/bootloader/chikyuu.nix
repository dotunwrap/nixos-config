{
  boot = {
    loader = {
      systemd-boot.enable = true;
      efi.canTouchEfiVariables = true;
      timeout = 2;
    };

    initrd.enable = true;

    consoleLogLevel = 3;
  };
}
