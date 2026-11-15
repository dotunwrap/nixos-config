{
  # NOTE: `intoAttr = [ ]` everywhere, or Den's schema auto-instantiates
  # `nixosConfigurations.<name>` and collides with system-configs.nix's entry.
  den.hosts.x86_64-linux = {
    chikyuu = {
      intoAttr = [ ];
      users.gabby.classes = [ "homeManager" ];
    };
    # NOTE: no users.nia here; see TODO.md.
    europa.intoAttr = [ ];
    kaiousei = {
      intoAttr = [ ];
      users.gabby.classes = [ "homeManager" ];
    };
    meiousei = {
      intoAttr = [ ];
      users = {
        gabby.classes = [ "homeManager" ];
        nia.classes = [ "homeManager" ];
      };
    };
    suisei = {
      intoAttr = [ ];
      users.nia.classes = [ "homeManager" ];
    };
  };
}
