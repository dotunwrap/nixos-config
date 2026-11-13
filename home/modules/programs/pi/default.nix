_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;

  # Pi packages added to ~/.pi/agent/settings.json. npm sources are pinned: bump the
  # version here only after reviewing the new release.
  piPackages = [
    "git:github.com/nyoshe/pi-harness-config"
  ];

  # graphify (PyPI `graphifyy`) is installed with uv against Nix's Python, since uv's
  # own downloaded interpreters cannot run on NixOS. Pinned: bump only after review.
  graphifyVersion = "0.9.107";
in
{
  config = lib.mkIf cfg.enable {
    home = {
      activation = {
        # Declare Pi packages. settings.json is Pi-owned (it also holds model and
        # thinking choices), so merge instead of replacing the file. An existing entry
        # for the same package at another version is dropped, so a pin bump replaces it.
        piHarnessPackage = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="$HOME/.pi/agent/settings.json"
          run mkdir -p "$(dirname "$settings")"
          [ -s "$settings" ] || echo '{}' > "$settings"
          tmp="$(mktemp)"
          ${lib.getExe pkgs.jq} \
            --argjson pkgs ${lib.escapeShellArg (builtins.toJSON piPackages)} \
            'def id: sub("@[^@/]*$"; "");
             .packages = (((.packages // []) | map(select(id as $i | ($pkgs | map(id) | index($i)) == null))) + $pkgs)' \
            "$settings" > "$tmp" && run install -m 644 "$tmp" "$settings"
          rm -f "$tmp"
        '';

        # Install the graphify CLI, then its Pi skill (written to ~/.pi/agent/skills/graphify).
        # Needs network on first run; a failure only warns so activation still succeeds.
        graphify = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          export UV_PYTHON_DOWNLOADS=never UV_PYTHON=${lib.getExe pkgs.python3}
          if ${lib.getExe pkgs.uv} tool install --quiet "graphifyy==${graphifyVersion}" \
            && "$HOME/.local/bin/graphify" install --platform pi >/dev/null; then
            :
          else
            echo "warning: graphify install failed; rerun home-manager switch with network" >&2
          fi
        '';
      };

      packages = [
        pkgs.pi-coding-agent
        pkgs.uv
      ];

      sessionPath = [ "$HOME/.local/bin" ];
    };
  };
}
