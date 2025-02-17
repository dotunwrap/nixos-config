{ lib, ... }:

{
  myUser = {
    nvf.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
  };
}
