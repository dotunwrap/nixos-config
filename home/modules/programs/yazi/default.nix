_:
{
  pkgs,
  config,
  lib,
  ...
}:
let
  cfg = config.programs.yazi;
in
{
  config = lib.mkIf cfg.enable {
    # NOTE: This silences an eval warning for Yazi on systems with home.stateVersion being less than 26.05
    programs.yazi = {
      # TODO: Switch back to the bleeding edge build (`yazi.packages.${system}.default`)
      # once https://github.com/sxyazi/yazi/pull/4502 is merged. Upstream's flake is
      # missing pkg-config/oniguruma, which nixpkgs' cargoSetupHook now requires.
      package = pkgs.yazi;
      shellWrapperName = "y";
    };
  };
}
