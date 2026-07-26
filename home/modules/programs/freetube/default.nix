_:
{ config, lib, ... }:
let
  cfg = config.programs.freetube;
in
{
  config = lib.mkIf cfg.enable {
    # TODO: Configure activation script to import subscriptions
    programs.freetube.settings = {
      checkForUpdates = lib.mkDefault false;
      defaultQuality = lib.mkDefault "1080";
      hideUpcomingPremieres = lib.mkDefault true;
      hideChannelShorts = lib.mkDefault true;
      useSponsorBlock = lib.mkDefault true;
      sponsorBlockInteraction.skip = lib.mkDefault "doNothing";
    };
  };
}
