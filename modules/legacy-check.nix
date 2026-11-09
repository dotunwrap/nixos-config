{ lib, config, ... }:
let
  # NOTE: expected sets mirror README.md's host/user list.
  assertExactKeys =
    name: expected: actual:
    let
      missing = lib.subtractLists actual expected;
      extra = lib.subtractLists expected actual;
    in
    if missing == [ ] && extra == [ ] then
      true
    else
      throw "flake.${name} regressed: missing ${builtins.toJSON missing}, extra ${builtins.toJSON extra}";
in
{
  perSystem =
    { pkgs, ... }:
    {
      checks.legacy-bridge-manifest =
        assert assertExactKeys "nixosConfigurations" [
          "chikyuu"
          "europa"
          "kaiousei"
          "meiousei"
          "suisei"
        ] (builtins.attrNames config.flake.nixosConfigurations);
        # All 5 Home Manager profiles migrated to NixOS-integrated home-manager
        # (home-manager.users.<name> inside each host's own nixosSystem) --
        # standalone flake.homeConfigurations is retired, not replaced.
        assert assertExactKeys "homeConfigurations" [ ] (
          builtins.attrNames config.flake.homeConfigurations
        );
        pkgs.runCommand "legacy-bridge-manifest-check" { } "touch $out";

      nix-unit.tests = {
        testAssertExactKeysPassesWhenSetsMatch = {
          expr =
            assertExactKeys "x"
              [
                "a"
                "b"
              ]
              [ "a" "b" ];
          expected = true;
        };
        testAssertExactKeysThrowsWithMissingAndExtra = {
          expr =
            assertExactKeys "x"
              [
                "a"
                "b"
              ]
              [ "a" "c" ];
          expectedError = {
            type = "ThrownError";
            msg = "flake\\.x regressed: missing \\[\"b\"\\], extra \\[\"c\"\\]";
          };
        };
      };
    };
}
