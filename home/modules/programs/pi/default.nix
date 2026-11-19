_:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;

  # Pi packages added to ~/.pi/agent/settings.json. pi-harness-config (with its pinned
  # pi-web-access and pi-open-tui) is added by its own Home Manager module as a store path.
  piPackages = [ "npm:pi-llama-swap" ];

  # Entries that module already provides; dropped from settings.json so they do not load
  # twice (a duplicate makes every extension fail with "Tool ... conflicts").
  bundledPiPackages = [
    "git:github.com/nyoshe/pi-harness-config"
    "npm:pi-web-access"
    "npm:pi-open-tui"
  ];

  # Model Pi starts with, set only while settings.json has none so /model choices stick.
  defaultModel = "qwen3.8-27b";

  # The router's models as Pi's models.json wants them. Qwen thinks, and the Qwen3.8 servers
  # read images, so every entry says so.
  routerProvider = lib.optionalAttrs (cfg.routerProvider != null) {
    inherit (cfg.routerProvider) baseUrl;
    api = "openai-completions";
    # llama-swap ignores the key, but Pi hides a provider that has none.
    apiKey = "local";
    # Pi picks how to switch thinking from the URL, and a loopback or Tailscale address says nothing.
    # These are all Qwen3.8 models, which take enable_thinking through the chat template.
    compat.thinkingFormat = "qwen-chat-template";
    models = lib.mapAttrsToList (id: contextWindow: {
      inherit id contextWindow;
      reasoning = true;
      input = [
        "text"
        "image"
      ];
    }) cfg.routerProvider.models;
  };

  # graphify (PyPI `graphifyy`) is installed with uv against Nix's Python, since uv's
  # own downloaded interpreters cannot run on NixOS. Pinned: bump only after review.
  graphifyVersion = "0.9.107";
in
{
  options.programs.pi.routerProvider = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.submodule {
        options = {
          baseUrl = lib.mkOption {
            type = lib.types.str;
            example = "http://dosei:18020/v1";
            description = "OpenAI-compatible base URL of the llama-swap router.";
          };
          models = lib.mkOption {
            type = lib.types.attrsOf lib.types.int;
            description = "Model ids the router lists, each with its context window in tokens.";
          };
        };
      }
    );
    default = null;
    description = ''
      A llama-swap router (one that starts and stops local backends as models are requested) as
      a Pi provider named `local-llm`, merged into ~/.pi/agent/models.json and used as Pi's
      default provider. Null leaves models.json alone.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Adds pi-harness-config's store path to settings.json (see its Home Manager module).
    programs.pi.harness.enable = true;

    home = {
      activation = {
        # models.json is Pi-owned, so merge only the local-llm provider into it.
        piRouterProvider = lib.mkIf (cfg.routerProvider != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            models="$HOME/.pi/agent/models.json"
            run mkdir -p "$(dirname "$models")"
            [ -s "$models" ] || echo '{}' > "$models"
            tmp="$(mktemp)"
            # The router advertises each model's context window and input types in /v1/models, so
            # prefer that over the declared numbers; they remain the fallback while it is down
            # (and for a model it lists without a window).
            live="$(${lib.getExe pkgs.curl} -fsS --max-time 5 ${lib.escapeShellArg "${cfg.routerProvider.baseUrl}/models"} 2>/dev/null || true)"
            echo "$live" | ${lib.getExe pkgs.jq} -e '.data | length > 0' >/dev/null 2>&1 || live='{"data":[]}'
            ${lib.getExe pkgs.jq} \
              --argjson provider ${lib.escapeShellArg (builtins.toJSON routerProvider)} \
              --argjson live "$live" \
              '($live.data | map({key: .id, value: .}) | from_entries) as $l
               | .providers["local-llm"] = ($provider
                 | .models |= map(
                     ($l[.id] // {}) as $m
                     | (($m.context_length // 0) as $c | if $c > 0 then .contextWindow = $c else . end)
                     | (($m.architecture.input_modalities // []) as $in
                        | if ($in | length) > 0 then .input = $in else . end)))' \
              "$models" > "$tmp" && run install -m 644 "$tmp" "$models"
            rm -f "$tmp"
          ''
        );

        # Declare Pi packages (named apart from the harness module's own piHarnessPackage).
        # settings.json is Pi-owned (it also holds model and
        # thinking choices), so merge instead of replacing the file. An existing entry
        # for the same package at another version is dropped, so a pin bump replaces it.
        piSettings = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          settings="$HOME/.pi/agent/settings.json"
          run mkdir -p "$(dirname "$settings")"
          [ -s "$settings" ] || echo '{}' > "$settings"
          tmp="$(mktemp)"
          ${lib.getExe pkgs.jq} \
            --argjson pkgs ${lib.escapeShellArg (builtins.toJSON piPackages)} \
            --arg model ${lib.escapeShellArg defaultModel} \
            --argjson bundled ${lib.escapeShellArg (builtins.toJSON bundledPiPackages)} \
            'def id: sub("@[^@/]*$"; "");
             (if .defaultProvider == "llama.cpp" then del(.defaultProvider, .defaultModel) else . end) |
             .defaultProvider //= "local-llm" | .defaultModel //= $model |
             .packages = (((.packages // []) | map(select(id as $i | (($pkgs + $bundled) | map(id) | index($i)) == null))) + $pkgs)' \
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

      # pi-llama-swap discovers the router's models live; it wants the router's root URL.
      sessionVariables = lib.mkIf (cfg.routerProvider != null) {
        LLAMA_SWAP_URL = lib.removeSuffix "/v1" cfg.routerProvider.baseUrl;
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
