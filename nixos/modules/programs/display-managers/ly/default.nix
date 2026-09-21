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
      };
    };

    # NOTE:
    # nixpkgs' default ly PAM stack is `auth substack login`, which inherits
    # the system `login` service's ordering: pam_fprintd (sufficient) before
    # pam_unix (sufficient). That means pressing Enter after typing the
    # correct password still blocks on a fingerprint read first, since PAM
    # evaluates the stack top-to-bottom in one call.
    # (https://github.com/NixOS/nixpkgs/issues/171136)
    #
    # We are going to resolve this by just reordering `login` itself so
    # pam_unix is tried before pam_fprintd. ly, and tty logins (which share the
    # `login` PAM service), then try the typed password first and only fall
    # back to the fingerprint reader afterward.
    security.pam.services.login.rules.auth.fprintd.order = lib.mkIf config.services.fprintd.enable (
      config.security.pam.services.login.rules.auth.unix.order + 50
    );
  };
}
