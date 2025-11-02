_:
{ config, lib, ... }:
let
  cfg = config.programs.alacritty;
in
{
  config = lib.mkIf cfg.enable {
    programs.alacritty = {
      settings = {
        font = {
          normal = {
            family = "FiraCode Nerd Font"; # TODO: Change this to MonoLisa
            style = "Regular";
          };
        };
      };
    };
  };
}
