{ lib, ... }:

{
  myUser = {
    nvf.enable = lib.mkDefault true;
    rust.enable = lib.mkDefault true;
    c.enable = lib.mkDefault true;
    javascript.enable = lib.mkDefault true;
  };
}
