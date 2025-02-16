{ lib, ... }:

{
  myUser = {
    rust.enable = lib.mkDefault true;
  };
}
