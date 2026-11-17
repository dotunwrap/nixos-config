# Contributing

This is a personal, flake-based NixOS + Home Manager configuration. It isn't
actively seeking outside contributors, and pull requests may be declined or
left unmerged if they don't fit the author's own machines and workflow. That
said, if you'd like to contribute anyway — a fix, a cleanup, something
reusable for your own setup — here's the process.

## Before you start

Read [`CLAUDE.md`](CLAUDE.md) for the detailed conventions this repo follows.
The highlights:

- Commit messages follow [Conventional Commits](https://www.conventionalcommits.org/).
- GPG-signing commits is strongly encouraged, not required.
- Formatting/linting (`treefmt`, `statix`, `deadnix`) is enforced via devenv
  git-hooks — don't fight or bypass them.
- Run `just check` after any change.
- Rebuilds go through [`nh`](https://github.com/nix-community/nh)
  (`just ossw` / `just hmsw` / `just switch`), never raw
  `nixos-rebuild`/`home-manager`.
- The release model is tag-based: `main` is bleeding-edge, stable releases
  are immutable git tags.

## Making a change

1. Fork and branch from `main`.
2. Make your change, following the module/bundle structure described in
   `CLAUDE.md`.
3. Run `just check` and fix anything it flags.
4. Open a pull request against `main` with a Conventional Commits-style
   title and a clear description of what changed and why.

## Reporting issues

Open a GitHub issue with enough detail to reproduce: which host/user profile
is affected, the relevant `nix flake check`/build output, and what you
expected instead.
