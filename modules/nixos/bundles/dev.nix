{ lib, ... }:

{
  mySystem = {
    rust.enable = lib.mkDefault true;
  };
}
