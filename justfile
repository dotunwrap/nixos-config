#!/usr/bin/env -S just --justfile

set default-list
set lazy
set lists
set no-exit-message
set quiet
set unstable

hostname := `hostname`
hosts := ['chikyuu', 'europa', 'kaiousei', 'meiousei', 'suisei']

[group('Help')]
[arg('recipe', help="The recipe to display the usage of")]
help recipe='':
  just {{ if recipe == '' { '--list --unsorted' } else { f'--usage {{recipe}}' }}}

# statix/deadnix/jq/treefmt only ever come from the dev shell, never a
# system/profile install -- point at devenv (or its nix-native fallback).
[private]
_need_dev tool:
  {{
    if which(tool) != [] { ''
    } else if which('devenv') != [] {
      error(tool + ' is not on PATH. Run `devenv shell` to enter the dev environment, which provides it.')
    } else {
      error(tool + ' is not on PATH, and `devenv` is not installed. devenv is the preferred dev environment for this repo (https://devenv.sh); `nix develop` gives the plain Nix devShell with the same tools.')
    }
  }}

# nh/nixos-option/rg/jq/tailscale/gh/cachix/nix-auth are meant to be present
# on every one of this flake's hosts already -- if one is missing, say where
# it should have come from.
[private]
_need_sys tool source:
  {{ if which(tool) != [] { '' } else { error(tool + ' is not on PATH, but should ship via ' + source + '. If it is missing, the last switch may not have applied cleanly.') } }}

# A brand-new file is invisible to `nix eval`/`nix build` until git knows
# about it at all -- `-N` registers its path without staging real content,
# so it never bleeds into an unrelated commit.
[private]
_track_new:
  git add -N -A

# Prints the full tree of flake outputs (hosts, checks, devShells, ...)
[group('Flake')]
show *args: _track_new
  nix flake show {{args}}

# Lists the hosts this flake currently defines (ground truth for `hosts` above)
[group('Flake')]
hostlist: _track_new (_need_sys 'jq' 'the baseline home-manager profile (modules/defaults.nix)')
  nix eval --json .#nixosConfigurations --apply builtins.attrNames | jq -r '.[]'

# Updates the flake inputs (defaults to all inputs) and commits the lock file
[group('Flake')]
update *inputs:
  nix flake update --commit-lock-file {{inputs}}

# Regenerates flake.nix from the flake-file.inputs/nixConfig/outputs declared across modules/
[group('Flake')]
genflake: _track_new
  nix run .#write-flake

# Wraps nix-auth (status/login/logout) -- avoids flake-fetch rate limits on the many github: inputs here
[group('Flake')]
auth *args: (_need_sys 'nix-auth' 'the baseline home-manager profile (modules/defaults.nix)')
  nix-auth {{args}}

# Wraps cachix (push/use/...) for this repo's binary caches
[group('Flake')]
cachix *args: (_need_sys 'cachix' 'the baseline systemPackages (modules/defaults.nix)')
  cachix {{args}}

# Shows the substituters and trusted keys actually in effect right now
[group('Flake')]
caches: (_need_sys 'rg' 'the baseline home-manager profile (modules/defaults.nix)')
  nix config show | rg -i "substituters|trusted-public-keys"

# Shows an option's value, declaring module, and defining module(s) for a host (incl. nested home-manager.users.<name>.* paths)
[group('Debug')]
[arg('host', pattern=hosts)]
opt $option host=hostname *args: _track_new (_need_sys 'nixos-option' 'the base NixOS system closure')
  nixos-option --flake ".#{{host}}" "$option" {{args}}

# Evaluates any flake attribute, e.g. nixosConfigurations.kaiousei.config.networking.hostName
[group('Debug')]
dig attr *args: _track_new
  nix eval ".#{{attr}}" {{args}}

# Searches modules/ for every reference to a term (option path, aspect, input, ...)
[group('Debug')]
grep $pattern *args: (_need_sys 'rg' 'the baseline home-manager profile (modules/defaults.nix)')
  rg -n {{args}} -- "$pattern" modules

# Shows every module referencing a flake input, plus its locked revision
[group('Debug')]
input $name: (_need_sys 'rg' 'the baseline home-manager profile (modules/defaults.nix)') (_need_sys 'jq' 'the baseline home-manager profile (modules/defaults.nix)')
  rg -n -- "inputs\.$name\b" modules || true
  nix flake metadata --json | jq -r --arg n "$name" '.locks.nodes[$n] // ("no such locked input: " + $n)'

# Explains why `pkg` ends up in a host's closure
[group('Debug')]
[arg('pkg', help='A precise installable, e.g. nixpkgs#ripgrep or a store path')]
[arg('host', pattern=hosts)]
whydepends $pkg host=hostname *args: _track_new
  nix why-depends ".#nixosConfigurations.{{host}}.config.system.build.toplevel" "$pkg" {{args}}

# Prints a host's closure size
[group('Debug')]
[arg('host', pattern=hosts)]
size host=hostname: _track_new
  nix path-info -Sh $(nix build ".#nixosConfigurations.{{host}}.config.system.build.toplevel" --no-link --print-out-paths)

# Diffs the store closures of two hosts
[group('Debug')]
[arg('host1', pattern=hosts)]
[arg('host2', pattern=hosts)]
diffhosts host1 host2: _track_new
  set -- $(nix build ".#nixosConfigurations.{{host1}}.config.system.build.toplevel" ".#nixosConfigurations.{{host2}}.config.system.build.toplevel" --no-link --print-out-paths); nix store diff-closures "$1" "$2"

# Previews a switch for a host -- what would change, with zero side effects
[group('Debug')]
[arg('host', pattern=hosts)]
dry host=hostname *args: _track_new (_need_sys 'nh' 'the programs.nh NixOS module')
  nh os switch -H {{host}} --dry --diff always {{args}}

# Searches NixOS/home-manager options or nixpkgs packages
[group('Debug')]
search *query: (_need_sys 'nh' 'the programs.nh NixOS module')
  nh search {{query}}

# Loads a host's configuration into an interactive nix repl
[group('Debug')]
[arg('host', pattern=hosts)]
repl host=hostname: _track_new (_need_sys 'nh' 'the programs.nh NixOS module')
  nh os repl -H {{host}}

# Rebuilds the local NixOS configuration and activates it
[group('System')]
switch *args: _track_new (_need_sys 'nh' 'the programs.nh NixOS module')
  nh os switch {{args}}

# Builds a host's configuration without activating it (shows a package diff)
[group('System')]
[arg('host', pattern=hosts)]
build host=hostname *args: _track_new (_need_sys 'nh' 'the programs.nh NixOS module')
  nh os build -H {{host}} --diff always {{args}}

# Wraps tailscale -- `just ts status` alone already surveys the whole fleet
[group('System')]
ts *args: (_need_sys 'tailscale' 'services.tailscale.enable (modules/defaults.nix)')
  tailscale {{args}}

alias gc := clean
# Garbage collects all but the 3 latest profiles
[group('System')]
clean *args: (_need_sys 'nh' 'the programs.nh NixOS module')
  nh clean all --keep 3 --ask {{args}}

# Rolls back the local system to a previous generation
[confirm]
[group('System')]
rollback *args: (_need_sys 'nh' 'the programs.nh NixOS module')
  nh os rollback --ask {{args}}

# Lists available system generations (nixos-rebuild, not `nh os info` -- nh 4.4.2's date column reads the store path's own mtime, which Nix normalizes to the epoch; the profile symlink nixos-rebuild reads has the real one)
[group('System')]
gens:
  nixos-rebuild list-generations

# Evaluates every flake check (treefmt, nix-unit, flake-file drift, ...)
[group('Checks')]
check *args: _track_new
  nix flake check --keep-going {{args}}

# Builds a host's full closure via its ciChecks entry (never run by `check`)
[group('Checks')]
[arg('host', pattern=hosts)]
ci host=hostname *args: _track_new
  nix build ".#ciChecks.x86_64-linux.nixos-{{host}}" {{args}}

# Shows recent GitHub Actions runs for this repo
[group('Checks')]
runs *args: (_need_sys 'gh' 'the baseline home-manager profile (modules/defaults.nix)')
  gh run list {{args}}

[private]
_statix: (_need_dev 'statix')
  statix check .

[private]
_deadnix: (_need_dev 'deadnix')
  deadnix .

# Runs statix + deadnix directly (faster than a full `devenv test`)
[parallel]
[group('Checks')]
lint: _statix _deadnix

# Formats the repo via treefmt (works even without devenv running)
[group('Checks')]
fmt *args:
  nix fmt -- {{args}}

# Stages all changes in the worktree (unless --nostage) and creates a new conventional commit
[group('Version Control')]
[arg('type', pattern=['feat', 'fix', 'chore', 'ci', 'docs', 'refactor', 'revert', 'perf', 'build', 'style', 'test'], help='The type of the commit')]
[arg('scope', short, multiple, help='Scope that this commit affects')]
[arg('breaking', short='!', long, flag, help='Flag this commit as a breaking change')]
[arg('nostage', long, flag, help='Skip auto-staging; commit only what is already staged')]
[arg('subject', help='The subject of the commit')]
[arg('body', help='The body of the commit')]
commit type subject breaking scope=[] body nostage:
  {{ if nostage { '' } else { 'git add -A' } }}
  git commit -m '{{type}}{{if !scope { '' } else { f'({{join_list(scope, ',')}})'}}}{{if breaking { '!' } else { '' }}}: {{lowercase(subject)}}' -m '{{body}}'

# Shows recent commit history as a graph
[group('Version Control')]
log *args:
  git log --oneline --graph --decorate -20 {{args}}

# Stages everything (unless --nostage) and amends it into the most recent commit (rewrites local history)
[confirm]
[group('Version Control')]
[arg('nostage', long, flag, help='Skip auto-staging; amend using only what is already staged')]
amend nostage:
  {{ if nostage { '' } else { 'git add -A' } }}
  git commit --amend --no-edit

# Un-commits the last commit but keeps its changes staged
[confirm]
[group('Version Control')]
undo:
  git reset --soft HEAD^
