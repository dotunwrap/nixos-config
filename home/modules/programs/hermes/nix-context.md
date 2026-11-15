This machine is configured with Nix. The config is a flake at /etc/nixos (git repo, branch main, remote dotunwrap/nixos-config).

Layout:

- flake.nix declares inputs; parts/ holds flake-parts wiring (system-configs.nix, home-configs.nix, nixos-modules.nix, home-modules.nix).
- nixos/configurations/<host>.nix are the hosts: chikyuu, dosei, europa, kaiousei, meiousei, suisei. Check `hostname` to see which one you are on.
- nixos/modules/ (bundles, core, drivers, programs) are NixOS modules; home/modules/ (bundles, misc, programs, services, themes) are Home Manager modules; home/configurations/ has per-user configs.
- The local LLM server on dosei is HyperQwen (patched vLLM, model `qwen3.8-27b`, with vision: one image per request, the vision tower's weights in host RAM): nixos/modules/bundles/hyperqwen/default.nix, unit hyperqwen.service, other hosts reach it at http://dosei:18020, which is a llama-swap router (hyperqwen-router.service) listing `qwen3.8-27b` and `swift-1.5` (Swift 1.5 fine-tune, unit hyperqwen-swift.service); requesting the other model stops one unit and cold-starts the other, which takes minutes. It conflicts with llama-cpp.service over the GPUs, so starting one stops the other. The older llama.cpp router is nixos/modules/bundles/local_LLM/default.nix (http://dosei:8080, presets generated from it; per-model overrides in nixos/configurations/dosei.nix).
- Hermes (you) is configured in home/modules/programs/hermes/default.nix; this text is loaded from nix-context.md beside it.

Rules of thumb:

- NixOS and Home Manager are applied separately. Home Manager is standalone: `home-manager switch --flake '/etc/nixos#nia@dosei'`; system: `sudo nixos-rebuild switch --flake '/etc/nixos#dosei'`. Always quote the flake ref (zsh treats # as a glob). sudo needs a password you cannot enter, so ask the user to run it.
- Change config in the repo, not in generated files. ~/.hermes/config.yaml is merged from Nix settings on activation, and `hermes config set` is refused because the install is managed. Keys removed from Nix stay in config.yaml until deleted by hand.
- This is NixOS: no generic python3 or downloaded binaries. python3 and chromium are provided from nixpkgs (the browser tool is pinned to that chromium), so do not run `hermes pm install` or download browsers. For any other missing tool use `nix run nixpkgs#<pkg>` or `nix shell nixpkgs#<pkg>`; add permanent ones to extraPackages in the Hermes module.
- /nix/store is read-only; /run/llama-cpp/presets.ini is generated, so edits there do not persist.
- Commits run pre-commit hooks (deadnix, statix, treefmt, nix-auto-follow, ripsecrets). Do not bypass them with --no-verify without being told to. Do not push or rebuild unless asked.
- Check changes with `nix eval` or `nix build --no-link` on the specific output before suggesting a switch.
