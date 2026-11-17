{ lib, ... }:
{
  # NOTE: `intoAttr = [ ]` everywhere, or Den's schema auto-instantiates
  # `nixosConfigurations.<name>` and collides with system-configs.nix's entry.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.hosts.x86_64-linux = {
    chikyuu = {
      intoAttr = [ ];
      users.gabby = { };
    };
    # NOTE: no users.nia here; see TODO.md.
    europa.intoAttr = [ ];
    kaiousei = {
      intoAttr = [ ];
      users.gabby = { };
    };
    meiousei = {
      intoAttr = [ ];
      users = {
        gabby = { };
        nia = { };
      };
    };
    suisei = {
      intoAttr = [ ];
      users.nia = { };
    };
  };
}
