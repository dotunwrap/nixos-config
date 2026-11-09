{
  # `intoAttr = [ ]` on every host: Den's own core schema (modules/policies/flake.nix,
  # always active, not an opt-in battery) auto-instantiates and routes any host whose
  # `intoAttr` isn't empty into `flake.nixosConfigurations.<name>` by default -- which
  # collides with the legacy-built entry of the same name during this incremental
  # migration. Opting out here is what makes `.mainModule` safe to splice manually
  # into the existing `parts/system-configs.nix` instead.
  den.hosts.x86_64-linux = {
    chikyuu = {
      intoAttr = [ ];
      users.gabby.classes = [ "homeManager" ];
    };
    europa = {
      intoAttr = [ ];
      users.nia = { };
    };
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
