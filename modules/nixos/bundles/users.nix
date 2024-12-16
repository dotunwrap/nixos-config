{ lib, config, inputs, outputs, myUtils, pkgs, ... }: let
  cfg = config.mySystem;
in {
  options.mySystem.users = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        userConfig = lib.mkOption {
	  default = {};
	  example = "DP-1";
	};
	userSettings = lib.mkOption {
	  default = {};
	  example = "{}";
	};
      };
    });
    default = {};
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
      backupFileExtension = ".bkp";

      extraSpecialArgs = {
        inherit inputs;
	inherit myUtils;
	outputs = inputs.self.outputs;
      };

      users =
        builtins.mapAttrs (name: user: { ... }: {
	  imports = [
	    (import user.userConfig)
	    outputs.homeManagerModules.default
	  ];
	})
	(config.mySystem.users);
    };

    users.users = builtins.mapAttrs (
      name: user:
        {
	  isNormalUser = true;
	  initialPassword = "password";
	  description = "";
	  shell = pkgs.zsh;
	  extraGroups = ["networkmanager" "wheel"];
	}
	// user.userSettings
    ) (config.mySystem.users);
  };
}
