{
  lib,
  config,
  inputs,
  outputs,
  myUtils,
  pkgs,
  ...
}:
let
  cfg = config.mySystem;
in
{
  options.mySystem = {
    userName = lib.mkOption {
      default = "garrett";
      description = ''
        username
      '';
    };

    userConfig = lib.mkOption {
      default = null;
      description = ''
        home-manager config path
      '';
    };

    userNixosSettings = lib.mkOption {
      default = { };
      description = ''
        NixOS user settings
      '';
    };
  };

  config = {
    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      extraSpecialArgs = {
        inherit inputs;
        inherit myUtils;
        outputs = inputs.self.outputs;
      };
      users = {
        ${cfg.userName} =
          { ... }:
          {
            imports = [
              (import cfg.userConfig)
              outputs.homeManagerModules.default
            ];
          };
      };
    };

    users.users.${cfg.userName} = {
      isNormalUser = true;
      initialPassword = "password";
      description = cfg.userName;
      shell = pkgs.zsh;
      extraGroups = [
        "networkmanager"
        "wheel"
      ];
    } // cfg.userNixosSettings;
  };
}
