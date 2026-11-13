# TODO

Temporary scratch list of outstanding work. Not meant to be permanent --
fold items into real docs/issues once they're resolved, delete this file
once it's empty.

## Open

- **europa**: has no real `users.users.nia` account yet, so she isn't
  declared on it in `modules/hosts.nix` (Den synthesizes a bare user stub
  for any declared entity, which fails NixOS's user assertions without a
  real account backing it). Add her `classes = [ "homeManager" ]` back once
  the account exists. More broadly, europa is still just a bare host +
  `development` aspect -- the actual home-server role (README) has no
  aspect of its own yet.
- **meiousei**: moving towards becoming an HTPC for couch gaming. Needs its
  own aspect (replacing `den.aspects.dwm` in `modules/hosts/meiousei.nix`)
  rather than reusing the desktop dwm setup.
- **niri.nix vicinae Mesa workaround**: `modules/aspects/niri.nix`'s
  `vicinaeMesa` override (vicinae's glibc is older than the system's,
  breaking EGL/Vulkan) should be removed once
  [vicinae#2040](https://github.com/vicinaehq/vicinae/issues/2040) is
  resolved upstream.
- **zen-browser bookmarks**: `modules/users/gabby/_zen/bookmarks.nix` is
  still an empty stub.
- **nix-auth token**: no GitHub token configured yet (`just auth status`
  reports none). Worth setting one up (`just auth login github`) given how
  many `github:` flake inputs this repo pulls -- real rate-limit risk.
- **CLAUDE.md is stale**: it still documents the pre-dendritic layout
  (`parts/`, `nixos/modules`, `home/modules`, `nixos/configurations`,
  `home/configurations`, `just osadd`/`just hmadd`), none of which exist
  anymore after the migration to `den.aspects.*`/`modules/`. Needs a full
  rewrite to match the current architecture.
- **den-diagram**: [github:denful/den-diagram](https://github.com/denful/den-diagram)
  is a companion flake (same author as `den`) that renders per-host aspect
  DAGs, a namespace graph, and fleet-wide views via mermaid. Worth adopting
  as its own task -- needs a new flake input plus a `modules/diagrams.nix`
  adapted to this repo's actual hosts/aspects (not the template's demo
  ones). `den.lib.capture.captureFleet {}` (already part of `den`, no extra
  input) is the lighter-weight alternative if full diagram rendering isn't
  worth it.

## Done (kept briefly for context, delete on next cleanup)

- ~~`just commit` required `-s`/`--scope` even though it's meant to be
  optional~~ -- fixed by giving `scope` a default of `[]`.
