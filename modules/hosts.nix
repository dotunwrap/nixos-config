{
  # `intoAttr = [ ]` on every host: Den's own schema auto-instantiates
  # `flake.nixosConfigurations.<name>` from any host whose `intoAttr` isn't
  # empty, which would collide with the entry modules/system-configs.nix
  # builds for the same name. Opting out here is what makes `.mainModule`
  # safe to splice into that instead.
  den.hosts.x86_64-linux = {
    chikyuu = {
      intoAttr = [ ];
      users.gabby.classes = [ "homeManager" ];
    };
    # No users.nia here -- see TODO.md.
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
