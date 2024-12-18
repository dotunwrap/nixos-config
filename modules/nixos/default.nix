{ config, lib, inputs, myUtils, ... }: let
  cfg = config.mySystem;

  features =
    myUtils.extendModules
    (name: {
      extraOptions = {
        mySystem.${name}.enable = lib.mkEnableOption "enable my ${name} configuration";
      };

      configExtension = config: (lib.mkIf cfg.${name}.enable config);
    })
    (myUtils.filesIn ./features);

  bundles =
    myUtils.extendModules
    (name: {
      extraOptions = {
        mySystem.bundles.${name}.enable = lib.mkEnableOption "enable ${name} module bundle";
      };

      configExtension = config: (lib.mkIf cfg.bundles.${name}.enable config);
    })
    (myUtils.filesIn ./bundles);
in {
  imports =
    [
      inputs.home-manager.nixosModules.home-manager
    ]
    ++ features
    ++ bundles;
  
  config = {
    nix.settings.experimental-features = ["nix-command" "flakes"];
    nixpkgs.config.allowUnfree = true;
    programs.nix-ld.enable = true;
  };
}
