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
    # No `users.nia` here: unlike the other 4 hosts, `nixos/configurations/europa.nix`
    # has no real `users.users.nia` account yet (still a commented-out TODO) -- Den
    # synthesizes a `users.users.nia` stub for ANY declared user entity regardless of
    # `classes`, which fails NixOS's own user assertions (isNormalUser/isSystemUser/
    # group all unset) the moment a real account doesn't back it. Add this back once
    # europa's real account exists.
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
