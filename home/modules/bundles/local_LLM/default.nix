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
  apiKeyFile = osCfg.apiKeyFile or null; # pragma: allowlist secret
  port = if osCfg != null then osCfg.port else 8080;
in
{
  options.bundles.local_LLM = {
    enable = lib.mkEnableOption "The local LLM bundle.";
  };

  config = lib.mkIf cfg.enable {
    home = {
      activation = {
        # Equivalent of `/login llama.cpp`. auth.json is Pi-owned (it holds other
        # providers' credentials too), so merge the entry instead of symlinking the file.
        piLlamaLogin = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          auth="$HOME/.pi/agent/auth.json"
          run mkdir -p "$(dirname "$auth")"
          [ -s "$auth" ] || echo '{}' > "$auth"
          tmp="$(mktemp)"
          key=""
          ${lib.optionalString (apiKeyFile != null)
            ''[ -r ${lib.escapeShellArg apiKeyFile} ] && key="$(grep -v '^#' ${lib.escapeShellArg apiKeyFile} | head -n1)"''
          }
          ${lib.getExe pkgs.jq} \
            --arg url "http://127.0.0.1:${toString port}" \
            --arg key "$key" \
            '."llama.cpp" = {type: "api_key", env: {LLAMA_BASE_URL: $url}} + (if $key != "" then {key: $key} else {} end)' \
            "$auth" > "$tmp" && run install -m 600 "$tmp" "$auth"
          rm -f "$tmp"
        '';
      };

      # Pi's built-in llama.cpp provider discovers every model on the router and
      # detects Qwen's thinking switch, so no models.json is needed.
      sessionVariables.LLAMA_BASE_URL = "http://127.0.0.1:${toString port}";
    };
  };
}
