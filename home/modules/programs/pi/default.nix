{ pi-harness-config, ... }:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.pi;

  # @sidshaytay/pi-llama-swap, pinned from npm. It registers the router's models as Pi's
  # `llama-swap` provider and turns reasoning on for every one (the bundled
  # @danielmeneses/pi-llama-swap hardcodes reasoning = false, which hides Pi's thinking selector).
  # Reasoning is off only for ids ending in `-uncensored`/`_uncensored` or holding `no-thinking`,
  # so keep router names from ending that way.
  llamaSwapExtension = pkgs.fetchzip {
    name = "pi-llama-swap-sidshaytay-0.1.2";
    url = "https://registry.npmjs.org/@sidshaytay/pi-llama-swap/-/pi-llama-swap-0.1.2.tgz";
    hash = "sha256-xW0rdVydKHNsMTFs243n36jWgNMo24p4EshIOjUvxic=";
  };

  # pi-harness-config without its bundled @danielmeneses/pi-llama-swap: two extensions
  # registering the `llama-swap` provider would fight over it. Everything else is linked from the
  # original, and only package.json's extension list changes.
  harnessPackage =
    let
      orig = pi-harness-config.packages.${pkgs.stdenv.hostPlatform.system}.default;
    in
    pkgs.runCommand "${orig.name}-no-llama-swap" { nativeBuildInputs = [ pkgs.jq ]; } ''
      mkdir $out
      for f in ${orig}/*; do
        [ "$(basename "$f")" = package.json ] || ln -s "$f" "$out/$(basename "$f")"
      done
      jq '.pi.extensions -= ["./node_modules/@danielmeneses/pi-llama-swap/index.ts"]' \
        ${orig}/package.json > $out/package.json
    '';

  # Pi packages added to ~/.pi/agent/settings.json. pi-harness-config (with its pinned
  # pi-web-access and pi-open-tui) is added by its own Home Manager module as a store path.
  piPackages = [ "${llamaSwapExtension}" ];

  # Entries that module already provides; dropped from settings.json so they do not load
  # twice (a duplicate makes every extension fail with "Tool ... conflicts").
  bundledPiPackages = [
    "git:github.com/nyoshe/pi-harness-config"
    "npm:pi-web-access"
    "npm:pi-open-tui"
    "npm:@danielmeneses/pi-llama-swap"
    "npm:@sidshaytay/pi-llama-swap"
  ];

  # Model Pi starts with, set only while settings.json has none so /model choices stick.
  defaultModel = "FN-125b-a6b-coder-iq1m";

  # The router's models, as dosei's local_LLM bundle names them. These are all Qwen3.8 models,
  # which take enable_thinking through the chat template, and Pi cannot tell that from a loopback
  # or Tailscale URL. Provider-level compat does not reach extension-registered models, so each
  # model needs its own modelOverrides entry. Keep in step with the routerName values under
  # nixos/modules/bundles/local_LLM; unknown IDs are ignored by Pi.
  routerModels = [
    "qwen3.8-27b-w4a16"
    "swift-1.5-27b-w4a16"
    "swift-1.5-27b-uncensored-w4a16"
    "FN-125b-a6b-iq3xxs"
    "FN-125b-a6b-coder-iq1m"
    "FN-125b-a6b-orca-coder-uncensored-iq1m"
    "swift-1.5-FN-125b-a6b-iq3xxs"
    "swift-1.5-uncensored-FN-125b-a6b-iq3xxs"
    "FN-125b-a6b-gyro-m-tq2"
    "FN-125b-a6b-gyro-coder-l-tq3"
    "FN-125b-a6b-exl3-2.68bpw"
  ];
  modelOverrides = lib.genAttrs routerModels (_: {
    reasoning = true;
    compat.thinkingFormat = "qwen-chat-template";
  });

  # graphify (PyPI `graphifyy`) is installed with uv against Nix's Python, since uv's
  # own downloaded interpreters cannot run on NixOS. Pinned: bump only after review.
  graphifyVersion = "0.9.107";
in
{
  options.programs.pi.llamaSwapUrl = lib.mkOption {
    type = lib.types.nullOr lib.types.str;
    default = null;
    example = "http://dosei:18020/v1";
    description = ''
      Base URL of a llama-swap router (one that starts and stops local backends as models are
      requested). It is written to the `llama-swap` section of ~/.pi/agent/settings.json, and
      pi-llama-swap registers the router's models as Pi's `llama-swap` provider, used as the
      default. Null leaves the section alone.
    '';
  };

  config = lib.mkIf cfg.enable {
    # Adds pi-harness-config's store path to settings.json (see its Home Manager module).
    programs.pi.harness = {
      enable = true;
      package = harnessPackage;
    };

    home = {
      activation = {
        # The router's models used to be a local-llm provider in models.json; pi-llama-swap
        # provides them now, so drop the stale copy.
        piDropLocalLlm = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          models="$HOME/.pi/agent/models.json"
          if [ -s "$models" ] && ${lib.getExe pkgs.jq} -e '.providers["local-llm"]' "$models" >/dev/null 2>&1; then
            tmp="$(mktemp)"
            ${lib.getExe pkgs.jq} 'del(.providers["local-llm"])' "$models" > "$tmp" && run install -m 644 "$tmp" "$models"
            rm -f "$tmp"
          fi
        '';

        # Tell Pi how to switch thinking for the router's models (see routerModels). Only the
        # llama-swap provider's modelOverrides are managed; the rest of models.json is kept.
        piLlamaSwapModels = lib.mkIf (cfg.llamaSwapUrl != null) (
          lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            models="$HOME/.pi/agent/models.json"
            run mkdir -p "$(dirname "$models")"
            [ -s "$models" ] || echo '{}' > "$models"
            tmp="$(mktemp)"
            ${lib.getExe pkgs.jq} \
              --argjson overrides ${lib.escapeShellArg (builtins.toJSON modelOverrides)} \
              '.providers["llama-swap"].modelOverrides = $overrides' "$models" > "$tmp" \
              && run install -m 644 "$tmp" "$models"
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
            --arg url ${lib.escapeShellArg (toString cfg.llamaSwapUrl)} \
            --argjson bundled ${lib.escapeShellArg (builtins.toJSON bundledPiPackages)} \
            'def id: sub("@[^@/]*$"; "");
             (if .defaultProvider == "llama.cpp" then del(.defaultProvider, .defaultModel) else . end) |
             (if .defaultProvider == "local-llm" then del(.defaultProvider, .defaultModel) else . end) |
             .defaultProvider //= "llama-swap" | .defaultModel //= $model |
             (if $url != "" then .["llama-swap"].url = $url else . end) |
             .packages = (((.packages // []) | map(select(
               (id as $i | (($pkgs + $bundled) | map(id) | index($i)) == null)
               and (test("pi-llama-swap") | not)
             ))) + $pkgs)' \
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
