_:
{ config, lib, ... }:
let
  cfg = config.services.mako;
in
{
  config = lib.mkIf cfg.enable {
    # TODO:
  };
}
