{ lib, inputs }:
let
  inherit (import ./module-helpers.nix lib inputs) callModule;

  fixture = ./tests/fixtures/module-helpers/simple-module.nix;
in
lib.runTests {
  testCallModuleWithNullArgsWrapsPathAsImportVerbatim = {
    expr = callModule fixture null;
    expected = {
      imports = [ fixture ];
      _file = fixture;
    };
  };

  testCallModuleWithNullArgsAndStringAddsFileAttr = {
    expr = callModule "a-string-module-reference" null;
    expected = {
      imports = [ "a-string-module-reference" ];
      _file = "a-string-module-reference";
    };
  };

  testCallModuleWithNonPathNonStringModuleOmitsFileAttr = {
    expr = callModule { fake = true; } null;
    expected = {
      imports = [ { fake = true; } ];
    };
  };

  testCallModuleWithArgsCallsImportAndKeepsFileAttrForPathModule = {
    expr = callModule fixture { foo = 1; };
    expected = {
      imports = [
        {
          receivedArgs = {
            foo = 1;
          };
        }
      ];
      _file = fixture;
    };
  };
}
