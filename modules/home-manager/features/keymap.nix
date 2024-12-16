{ pkgs, lib, ... }:

{
  options = {
    myUser.keybinds = lib.mkOption {
      default = {
        "$mainMod, A" = {
          "f"."f" = {
            exec = "brave";
          };
        };
      };
    };
  };

  config = let
    inherit (lib) getExe;
  in {
    myUser.keybinds = {
      "SUPER SHIFT, RETURN".package = pkgs.brave;

      "SUPER, p".script = ''
        ${getExe pkgs.playerctl} play-pause
      '';
    };
  };
}
