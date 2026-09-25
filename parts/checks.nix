{ lib, inputs, ... }:
{
  perSystem =
    { pkgs, ... }:
    let
      moduleHelpersFailures = import ./module-helpers.tests.nix { inherit lib inputs; };
    in
    {
      checks.module-helpers-tests = pkgs.runCommand "module-helpers-tests" { } (
        if moduleHelpersFailures == [ ] then
          "touch $out"
        else
          lib.debug.throwTestFailures { failures = moduleHelpersFailures; }
      );
    };
}
