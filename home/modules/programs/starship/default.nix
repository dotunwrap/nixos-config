_:
{
  config,
  lib,
  ...
}:
let
  cfg = config.programs.starship;
in
{
  options.programs.starship.prompt = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
  };

  config = lib.mkIf cfg.enable {
    programs.starship = {
      settings = lib.mkIf (config.programs.starship.prompt != null) (
        import ./prompts/${config.programs.starship.prompt}.nix lib
      );
    };
  };
}
