_:
{
  config,
  lib,
  osConfig ? null,
  pkgs,
  ...
}:
let
  cfg = config.bundles.local_LLM;
  osCfg = osConfig.bundles.local_LLM or null;
  port = if osCfg != null then osCfg.port else 8080;
in
{
  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle.";
  };

  config = lib.mkIf cfg.enable {
    home = {
      packages = [ pkgs.pi-coding-agent ];

      # Pi's built-in llama.cpp provider discovers every model on the router and
      # detects Qwen's thinking switch, so no models.json is needed.
      sessionVariables.LLAMA_BASE_URL = "http://127.0.0.1:${toString port}";

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
      '';
    };
  };
}
