{ nvim, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.nvim;
  inherit (pkgs.stdenv.hostPlatform) system;
  styled-nixvim =
    if config.stylix.enable && config.stylix.targets.nixvim.enable then
      cfg.package.extend config.stylix.targets.nixvim.exportedModule
    else
      cfg.package;
in
{
  options.programs.nvim = {
    package = lib.mkOption { default = nvim.packages.${system}.default; };
  };

  config = lib.mkIf cfg.enable {
    home.packages = [ styled-nixvim ];
  };
}
