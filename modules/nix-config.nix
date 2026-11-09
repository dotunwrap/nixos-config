{
  flake-file.nixConfig = {
    commit-lock-file-summary = "chore: Update flake.lock";
    extra-substituters = [
      "https://nix-community.cachix.org"
      "https://dotunwrap.cachix.org"
    ];
    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "dotunwrap.cachix.org-1:p7ePw6DuH9OjOqpzJUg/RJor+9tl3vKtjHGBACvthW0="
    ];
  };
}
