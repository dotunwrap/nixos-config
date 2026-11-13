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
    "npm:pi-web-access@0.47.0"
  ];

  # graphify (PyPI `graphifyy`) is installed with uv against Nix's Python, since uv's
  # own downloaded interpreters cannot run on NixOS. Pinned: bump only after review.
  graphifyVersion = "0.9.107";
in
{
  options.programs.pi.llamaBaseUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "http://dosei:8080";
    description = ''
      Base URL of a llama-server router (e.g. one reached over Tailscale) for Pi's
      built-in llama.cpp provider. Null leaves the provider unconfigured.
    '';
  };

  config = lib.mkIf cfg.enable {
    home = {
      activation = {
        # Equivalent of `/login llama.cpp`. auth.json is Pi-owned (it holds other
        # providers' credentials too), so merge the entry instead of symlinking the file.
        piLlamaLogin = lib.mkIf (cfg.llamaBaseUrl != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            auth="$HOME/.pi/agent/auth.json"
            run mkdir -p "$(dirname "$auth")"
            [ -s "$auth" ] || echo '{}' > "$auth"
            tmp="$(mktemp)"
            ${lib.getExe pkgs.jq} \
              --arg url ${lib.escapeShellArg cfg.llamaBaseUrl} \
              '."llama.cpp" = {type: "api_key", env: {LLAMA_BASE_URL: $url}}' \
              "$auth" > "$tmp" && run install -m 600 "$tmp" "$auth"
            rm -f "$tmp"
          ''
        );

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

      # Pi's built-in llama.cpp provider discovers every model on the router and
      # detects Qwen's thinking switch, so no models.json is needed.
      sessionVariables = lib.mkIf (cfg.llamaBaseUrl != null) {
        LLAMA_BASE_URL = cfg.llamaBaseUrl;
      };

      # Appended to Pi's default system prompt (SYSTEM.md would replace it). No
      # Qwen-specific prompt is published, so this is general coding-agent guidance
      # aimed at a local model: keep reasoning short, verify with tools, stay in scope.
      file.".pi/agent/APPEND_SYSTEM.md".text = ''
        ## Working style

        - Think briefly. Decide, then act; do not re-derive facts you have already established or deliberate over options you will not take.
        - Explore before editing: use `grep`, `find`, `ls` and `read` to understand the code, and read a file before changing it.
        - Make the smallest change that solves the task. Match the surrounding code's style, naming and comment density. Do not refactor, rename or reformat code you were not asked to touch.
        - Make one tool call at a time unless calls are independent. When you call a tool, do not also write a long explanation first.
        - Prefer `edit` over rewriting a whole file with `write`. Never overwrite a file you have not read.
        - After a change, verify it by running the relevant build, test or linter with `bash`. Report failures with the real output; do not claim success you have not seen.
        - Keep tool output small: pipe through `head`, `tail` or `grep` rather than dumping large files or logs.
        - Ask before destructive or hard-to-reverse actions (deleting files, force pushes, `rm -rf`, dropping data, system-wide installs).
        - If you are stuck after two attempts at the same approach, stop, say what you tried, and ask or change approach instead of looping.
        - Final answers should be short: what changed, what you verified, and anything left undone.

        ## Environment: NixOS

        - This machine runs NixOS. Tools are not installed globally and there is no `apt`, `pip install --user`, `npm install -g` or `/usr/bin`. If a command is not found, do not give up and do not install it system-wide.
        - Run a missing CLI tool in a temporary shell instead: `nix shell nixpkgs#<package> -c <command>` (or `nix-shell -p <package> --run '<command>'`). Use several packages when needed: `nix shell nixpkgs#jq nixpkgs#ripgrep -c ...`. Find the right package name with `nh search` or the `nix-search` skill; never guess it.
        - For anything larger than a one-off command (a project with a toolchain, several dependencies, builds or tests), set up a dev environment first: if the project has no `flake.nix` with a `devShells.default`, create one that lists its toolchain, `git add` the file so the flake can see it, then run every build, test and lint command through `nix develop -c <command>`. If a `flake.nix`, `shell.nix` or `.envrc` already exists, use it and do not replace it.
        - Prefer the project's pinned environment over ad-hoc `nix shell` once one exists.
        - Never run `nixos-rebuild`, `home-manager switch`, `nh os switch` or `sudo`. Edit the config and ask the user to apply it.
      '';
    };
  };
}
