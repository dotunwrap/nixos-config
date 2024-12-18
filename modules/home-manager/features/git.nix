{ lib, ... }:

{
  programs.git = {
    enable = true;
    userName = lib.mkDefault "username";
    userEmail = lib.mkDefault "example@example.com";
  };
}
