{
  den.aspects.europa.nixos =
    { ... }:
    {
      imports = [ ./_hardware/europa.nix ];

      networking = {
        hostName = "europa";
        networkmanager.enable = true;
      };

      services.libinput = {
        enable = true;
        touchpad = {
          tapping = true;
          naturalScrolling = true;
        };
      };

      time.timeZone = "America/New_York";
      i18n.defaultLocale = "en_US.UTF-8";
    };
}
