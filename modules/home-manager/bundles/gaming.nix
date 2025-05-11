{ lib, ... }:

{
  config = {
    myUser = {
      prism.enable = lib.mkDefault true;
    };
  };
}
