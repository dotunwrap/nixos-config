_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;

  # graphify (PyPI `graphifyy`) is installed with uv against Nix's Python, since uv's
  # own downloaded interpreters cannot run on NixOS. Pinned: bump only after review.
  graphifyVersion = "0.9.107";
in
{
  config = lib.mkIf cfg.enable {
    # Extensions, skills and prompt guidance come from the pi-harness-config flake input.
    programs.pi.harness.enable = true;

    home = {
      activation = {
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
