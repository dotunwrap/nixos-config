{ lib, config, inputs, outputs, myUtils, pkgs, ... }: let
  cfg = config.mySystem;
in {
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
      default = {};
      description = ''
        NixOS user settings
      '';
    };
  };

  config = {
    programs.zsh.enable = true;

    programs.hyprland.enable = cfg.hyprland.enable;

    services = lib.mkIf cfg.hyprland.enable {
      xserver.enable = true;
      displayManager = {
        defaultSession = "hyprland";
      };
    };

    home-manager = {
      useGlobalPkgs = true;
      useUserPackages = true;

      extraSpecialArgs = {
        inherit inputs;
	inherit myUtils;
	outputs = inputs.self.outputs;
      };
      users = {
        ${cfg.userName} = { ... }: {
	  imports = [
	    (import cfg.userConfig)
	    outputs.homeManagerModules.default
	  ];
	};
      };
    };

    users.users.${cfg.userName} =
      {
        isNormalUser = true;
	initialPassword = "password";
	description = cfg.userName;
	shell = pkgs.zsh;
	extraGroups = ["networkmanager" "wheel"];
      } // cfg.userNixosSettings;
  };
}
