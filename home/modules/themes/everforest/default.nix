_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.themes.everforest;
  filename = "everforest-${config.stylix.polarity}-${cfg.flavor}";
in
{
  options.themes.everforest.flavor = lib.mkOption {
    type = lib.types.enum [
      "hard"
      "medium"
      "soft"
    ];
    default = "medium";
    description = "The flavor of Everforest to use.";
  };

  config = lib.mkIf cfg.enable {
    stylix.base16Scheme =
      if config.stylix.polarity == "dark" then
        "${pkgs.base16-schemes}/share/themes/${filename}.yaml"
      else
        ./${filename}.yaml; # NOTE: This is because light variants have not been upstreamed yet
  };
}
