#!/usr/bin/env bash

set -euo pipefail

# Resolves nixVersions.stable for the nixpkgs revision pinned in flake.lock,
# so CI can install that exact Nix without needing Nix already present.

cd "$(dirname "${BASH_SOURCE[0]}")/.."

rev=$(jq -r '.nodes.nixpkgs.locked.rev' flake.lock)
file=$(curl -sf "https://raw.githubusercontent.com/NixOS/nixpkgs/$rev/pkgs/tools/package-management/nix/default.nix")

suffix=$(grep -m1 -E '^\s*stable = ' <<<"$file" | sed -E 's/.*self\.nix_([0-9_]+).*/\1/')
version=$(awk -v pat="nixComponents_$suffix =" '
  index($0, pat) { found = 1 }
  found && match($0, /version = "[^"]+"/) { print substr($0, RSTART + 11, RLENGTH - 12); exit }
' <<<"$file")

if [[ -z "$version" ]]; then
  echo "Failed to resolve nixVersions.stable for nixpkgs rev $rev" >&2
  exit 1
fi

echo "$version"
