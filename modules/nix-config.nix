let
  caches = import ./_data/caches.nix;
in
{
  flake-file.nixConfig = {
    commit-lock-file-summary = "chore: Update flake.lock";
    extra-substituters = map (c: c.url) caches;
    extra-trusted-public-keys = map (c: c.key) caches;
  };
}
