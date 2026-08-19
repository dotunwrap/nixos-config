_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.display-managers.ly;
in
{
  config = lib.mkIf cfg.enable {
    services.displayManager.ly = {
      enable = true;
      package = pkgs.ly;
      settings = {
        bigclock = "en";
        clear_password = true;
        default_input = "password";
        vi_mode = true;
        box_title = "${config.networking.hostName}";
        hide_system_users = true;
      };
    };

    # nixpkgs' default ly PAM stack is `auth substack login`, which inherits
    # the system `login` service's ordering: pam_fprintd (sufficient) before
    # pam_unix (sufficient). That means pressing Enter after typing the
    # correct password still blocks on a fingerprint read first, since PAM
    # evaluates the stack top-to-bottom in one call.
    # (https://github.com/NixOS/nixpkgs/issues/171136)
    #
    # Replace it with an explicit stack that tries pam_unix first, so
    # password+Enter never waits on the fingerprint reader, while fprintd
    # remains available as a sufficient fallback.
    security.pam.services.ly.rules.auth = lib.mkIf config.services.fprintd.enable {
      login.enable = false;
      unix = {
        order = 10000;
        control = "sufficient";
        modulePath = config.security.pam.pam_unixModulePath;
        args = [
          "try_first_pass"
          "likeauth"
          "nullok"
        ];
      };
      fprintd = {
        order = 10100;
        control = "sufficient";
        modulePath = "${config.services.fprintd.package}/lib/security/pam_fprintd.so";
      };
      deny = {
        order = 10200;
        control = "required";
        modulePath = "${config.security.pam.package}/lib/security/pam_deny.so";
      };
    };
  };
}
