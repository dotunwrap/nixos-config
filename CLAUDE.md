# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal, flake-based NixOS + Home Manager configuration (nixpkgs unstable) covering multiple hosts and users, built modularly via `flake-parts`. Real machines, real users — treat destructive rebuild/switch commands with care.

## Commands

Use `just` (see `justfile`) for common operations:

- `just check` — `nix flake check --keep-going`. Run this after any change.
- `just osev SYSTEM OUTPUT *ARGS` — `nix eval .#nixosConfigurations.<SYSTEM>.<OUTPUT>` (e.g. inspect a single option without building).
- `just hmev USER SYSTEM *ARGS` — `nix eval .#homeConfigurations."<USER>@<SYSTEM>"`.
- `just ossw` — `nh os switch` (applies the NixOS config to the current machine — only run when asked).
- `just hmsw` — `nh home switch` (applies the Home Manager config for the current user — only run when asked).
- `just switch` — runs both of the above.
- `just clean` — `nh clean all --keep 5 --keep-since 7d` (manual store cleanup; also runs automatically, see below).
- `just osadd PATH MODULE` / `just hmadd PATH MODULE` — scaffold a new NixOS/Home Manager module (see "Adding a new module" below). Do this instead of hand-writing the three touch points.

Rebuilds and cleanup go through [`nh`](https://github.com/nix-community/nh) rather than the stock `nixos-rebuild`/`home-manager`/`nix-collect-garbage` CLIs — it's available in the devshell/devenv and enabled system-wide via `nixos/modules/core/nh`, which also turns on `programs.nh.clean` (weekly, `--keep 5 --keep-since 7d`) and disables `nix.gc.automatic` in `core/nix` to avoid the two cleanup paths fighting each other.

Formatting/linting is handled by `treefmt` (nixfmt, shfmt, prettier) plus `statix` and `deadnix`, wired up via `devenv.nix` git-hooks — these run through `devenv test` / pre-commit, not as standalone scripts. If devenv isn't running, `nix fmt` invokes the same treefmt config directly (see `treefmt.nix`).

There is no application code, no test suite in the conventional sense, and no build in the CI-artifact sense — "correctness" here means `nix flake check` passing and the affected host's config evaluating/building cleanly (`just osev <host> config.system.build.toplevel` or `nix build .#nixosConfigurations.<host>.config.system.build.toplevel`).

## Architecture

### Flake-parts + a custom "registry" layer

`flake.nix` is a thin `flake-parts` shell that imports `parts/*.nix` plus the `nixos/configurations`, `home/configurations`, `home/modules`, `nixos/modules` directories. The real machinery lives in `parts/`:

- `parts/module-helpers.nix` — defines `callModule`/`submodule`, coercing a bare module path (or `{ module, extraArgs }`) into a wrapped module. Used by both module registries below.
- `parts/nixos-modules.nix` / `parts/home-modules.nix` — define the `dotunwrap.nixosModules` / `dotunwrap.homeManagerModules` options. Every entry registered here (a `name -> path` mapping) is wrapped and re-exposed as a flake output (`self.nixosModules`, `self.homeManagerModules`).
- `parts/system-configs.nix` / `parts/home-configs.nix` — define `dotunwrap.nixosConfigurations` / `dotunwrap.homeConfigurations`. For each entry, they build `finalModules` = a fixed set of baseline modules (overlays, stylix, niri-flake, vicinae, the host/user entry point, bootloader/hardware files for NixOS) **plus `builtins.attrValues self.nixosModules` / `self.homeManagerModules` — i.e. every registered module, unconditionally, for every host.** Nothing is actually applied unless its `enable` option is set; gating happens entirely inside each module via `lib.mkIf cfg.enable`.
- `parts/auxillary.nix` — `perSystem` devShell + `formatter` (treefmt).

Practical implication: importing a module into the registry is cheap and global — it does not mean it's active anywhere. Activation is 100% driven by `enable` options set in bundles or host/user configs.

### Bundles → Programs/Themes/Misc

- **Bundles** (`nixos/modules/bundles/*`, `home/modules/bundles/*`) are coarse feature groups (`base`, `dwm`, `niri`, `gaming`, `development`). A host/user turns bundles on via `activeBundles = [ "base" "niri" ... ];` (see e.g. `nixos/configurations/chikyuu.nix`); `nixos/modules/bundles/default.nix` / `home/modules/bundles/default.nix` fold that list into `bundles.<name>.enable = true`. Bundle modules are self-contained: `options.bundles.<name>` and `config = lib.mkIf cfg.enable { ... }` live in the same file, and a bundle typically flips on a batch of `programs.*`/`services.*` options (see `home/modules/bundles/niri/default.nix`).
- **Programs** (`{nixos,home}/modules/programs/*`) are per-application modules, one directory per program. Unlike bundles, these split declaration from implementation: `options.programs.<name>.enable` is declared centrally in `{nixos,home}/modules/programs/default.nix`, while `config = lib.mkIf cfg.enable { ... }` lives in `programs/<name>/default.nix`. **Both halves, plus the registry entry in `{nixos,home}/modules/default.nix`, must exist or the module silently does nothing** — always use `just osadd`/`just hmadd` (backed by `scripts/mkmodule.sh` and `templates/*-module.nix.template`) to scaffold new program modules so all three stay in sync.
- **Themes** (`home/modules/themes/*`) follow the bundle pattern (self-contained) and drive `stylix` when any theme is enabled.
- One known naming collision: Home Manager's own `programs.just` module already exists, so this repo's `just` program module is exposed as `programs.just_.enable`.

### Hosts and users

Defined in `nixos/configurations/default.nix` and `home/configurations/default.nix` as `name.system = "x86_64-linux"` entries (currently the only supported system). Each NixOS host has an entry point at `nixos/configurations/<host>.nix` plus `nixos/configurations/bootloader/<host>.nix` and `nixos/configurations/hardware/<host>.nix` (hardware files are generated by `nixos-generate-config`, don't hand-restyle them — `statix` explicitly ignores that path). Each Home Manager profile is `<user>@<host>`, entry point `home/configurations/<user>-at-<host>.nix`, importing shared per-user config from `home/configurations/shared/<user>/`.

Hosts/users, from `README.md`:

- `chikyuu` (gabby, desktop, dwm/X11, gaming)
- `europa` (nia, ThinkPad X1 Carbon, Niri/Wayland, previously her main machine, soon a home server)
- `kaiousei` (gabby, Framework 13 Pro, Niri/Wayland, main machine)
- `meiousei` (gabby + nia, desktop, Niri/Wayland, previously a gaming desktop, soon an HTPC)
- `suisei` (nia, Framework 13, Niri/Wayland, her main machine)

### Adding a new module

Prefer `just osadd <path> <module>` / `just hmadd <path> <module>` over hand-editing. This scaffolds `{nixos,home}/modules/<path>/<module>/default.nix` from the template, inserts `<module>.enable = mkEnableOption ...` into `{nixos,home}/modules/<path>/default.nix`, and adds the registry entry to `{nixos,home}/modules/default.nix`. It assumes the underlying package already exists in nixpkgs and is not enabled by default; edit the generated `config` block for anything beyond a trivial `environment.systemPackages`/`home.packages` addition. Note it does not handle adding options for the module — those must be defined by hand within the generated `default.nix` if the module needs configurable options beyond `enable`.

### Inputs worth knowing about

Several flake inputs are this author's own forks/projects, not upstream: `determinvim`, `niavim` (neovim configs consumed via `nvim.package`), `suckless` (dwm build), `monolisa` (private font, `git+ssh`), `niri-flake` is pinned to a fork (`epireyn/niri-flake`) because upstream is stale against current nixpkgs — check that fork's status before assuming upstream `sodiboo/niri-flake` behavior applies. `nix-auto-follow` (via `devenv.nix`) enforces that `flake.lock` `inputs.*.follows` stay deduplicated as a git-hook check, with one deliberate exception: `vicinae` does not follow our `nixpkgs` (and `vicinae-extensions` follows `vicinae/nixpkgs` instead of ours), because it's a large Qt6/CMake/C++ build — any drift from vicinae's own pin guarantees a cache miss against `vicinae.cachix.org` and a from-source rebuild. The hook is passed `--ignore vicinae` to allow this. General policy: prefer a real cache hit (build speed) over lock file dedup when the two conflict for a given input.

### CI

`.github/workflows/ci.yml` runs `devenv test` (which runs all git-hooks: treefmt, statix, deadnix, nil, action-validator, actionlint, nix-auto-follow check) on PRs and pushes to `main`. It does not build any host configs.
