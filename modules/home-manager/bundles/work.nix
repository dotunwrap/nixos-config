{ lib, ... }:

{
  myUser = {
    slack.enable = lib.mkDefault true;
  };
}
