{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) system;
  inherit (lib) getExe concatMapStringsSep mkIf;
  inherit (config.secretspec) secrets;

  autoFollow = inputs.nix-auto-follow.packages.${system}.default;
  treefmt = import ./modules/_data/treefmt.nix { inherit pkgs; };
  caches = import ./modules/_data/caches.nix;

  shellTools = [
    autoFollow
    treefmt
  ]
  ++ (with pkgs; [
    age
    deadnix
    git
    jq
    just
    nh
    nil
    sops
    statix
  ]);

  # NOTE: hand-maintained, like justfile's own `hosts` list (see its FIXME) --
  # these are display stats for the welcome banner, not read from the flake
  # itself, so a stale entry here is cosmetic rather than a correctness bug.
  # WARNING: keep every field plain ASCII. `pad`/*W below size columns off
  # `lib.stringLength`, which counts UTF-8 bytes, not display columns -- a
  # multi-byte char (e.g. an em dash or middle dot) pads short and visibly
  # misaligns that row's remaining columns.
  fleet = [
    {
      name = "chikyuu";
      planet = "Earth";
      users = [ "gabby" ];
      wm = "dwm (X11)";
      note = "Ryzen 9 9950X + RX 9070 XT -- gaming desktop";
    }
    {
      name = "europa";
      planet = "Europa";
      users = [ ];
      wm = "-";
      note = "ThinkPad X1 Carbon -- becoming a home server";
    }
    {
      name = "kaiousei";
      planet = "Neptune";
      users = [ "gabby" ];
      wm = "Niri (Wayland)";
      note = "Framework 13 Pro -- main machine";
    }
    {
      name = "meiousei";
      planet = "Pluto";
      users = [
        "gabby"
        "nia"
      ];
      wm = "dwm (X11)";
      note = "Ryzen 5 5600X + RTX 4070 Super -- becoming an HTPC";
    }
    {
      name = "suisei";
      planet = "Mercury";
      users = [ "nia" ];
      wm = "Niri (Wayland)";
      note = "Framework 13 -- nia's main machine";
    }
  ];

  pad =
    width: s:
    s + lib.concatStrings (builtins.genList (_: " ") (lib.max 0 (width - lib.stringLength s)));

  nameW = lib.foldl' (acc: h: lib.max acc (lib.stringLength h.name)) 0 fleet;
  planetW = lib.foldl' (acc: h: lib.max acc (lib.stringLength h.planet)) 0 fleet;
  usersW = lib.foldl' (
    acc: h: lib.max acc (lib.stringLength (lib.concatStringsSep ", " h.users))
  ) 1 fleet;
  wmW = lib.foldl' (acc: h: lib.max acc (lib.stringLength h.wm)) 0 fleet;

  # NOTE: row/note text (e.g. an apostrophe in "nia's") would break a plain
  # single-quoted printf string, so every dynamic value is passed through
  # escapeShellArg as its own argument and printed via %b, never interpolated
  # straight into the quotes.
  fleetRows = lib.concatMapStringsSep "\n" (
    h:
    let
      usersStr = if h.users == [ ] then "-" else lib.concatStringsSep ", " h.users;
      row = "\\033[1;36m${pad nameW h.name}\\033[0m  \\033[33m${pad planetW h.planet}\\033[0m  \\033[32m${pad usersW usersStr}\\033[0m  \\033[35m${pad wmW h.wm}\\033[0m  \\033[2m${h.note}\\033[0m";
      highlighted = "\\033[1;32m→ ${row}";
    in
    ''
      if [ "$host" = ${lib.escapeShellArg h.name} ]; then
        printf '    %b\n' ${lib.escapeShellArg highlighted}
      else
        printf '      %b\n' ${lib.escapeShellArg row}
      fi
    ''
  ) fleet;

  toolNames = lib.concatStringsSep ", " (
    lib.sort lib.lessThan (
      lib.unique (
        map (
          p:
          let
            n = p.pname or p.name or "?";
          in
          # NOTE: treefmt's package name carries its own config-hash suffix.
          if lib.hasPrefix "treefmt-with-config" n then "treefmt" else n
        ) shellTools
      )
    )
  );

  welcomeScript = pkgs.writeShellScriptBin "devenv-welcome" ''
    host="$(hostname)"

    printf '\n'
    printf '  \033[1;35m%s\033[0m \033[2m%s\033[0m\n' "dotunwrap/nixos" "-- flake-based NixOS + Home Manager configuration"
    printf '\n'
    printf '  \033[1;33mFleet\033[0m\n'
    ${fleetRows}
    printf '\n'
    printf '  \033[1;33mProject\033[0m\n'
    printf '    Multi-host, multi-user, flake-parts + dendritic NixOS/HM config.\n'
    printf '    Docs: \033[36mREADME.md\033[0m · \033[36mCLAUDE.md\033[0m · \033[36mTODO.md\033[0m\n'
    printf '\n'
    printf '  \033[1;33mTools in this shell\033[0m\n'
    printf '    %s\n' "${toolNames}"
    printf '\n'
    printf '  \033[1;33mCommon commands\033[0m\n'
    printf '    \033[36m%-16s\033[0m %s\n' "just help" "list every recipe this justfile defines"
    printf '    \033[36m%-16s\033[0m %s\n' "just check" "fast, eval-only flake check"
    printf '    \033[36m%-16s\033[0m %s\n' "just update" "update flake.lock/devenv.lock (--lockfile to pick one)"
    printf '    \033[36m%-16s\033[0m %s\n' "just switch" "rebuild and activate this host"
    printf '    \033[36m%-16s\033[0m %s\n' "just lint" "statix + deadnix, faster than a full devenv test"
    printf '    \033[36m%-16s\033[0m %s\n' "devenv test" "run the full git-hooks suite"
    printf '\n'
  '';
in
{
  cachix.pull = map (c: c.name) (builtins.filter (c: c.cachix) caches);

  packages = shellTools ++ [ welcomeScript ];

  enterShell = ''
    git config --local blame.ignoreRevsFile .git-blame-ignore-revs

    if [ -t 1 ]; then
      devenv-welcome
    fi
  '';

  languages = {
    nix.enable = true;
    shell.enable = true;
  };

  # NOTE: `devenv test` runs git-hooks (incl. treefmt/statix/deadnix)
  # before enterTest already; re-invoking them here would just double-maintain settings.
  git-hooks.hooks = {
    action-validator.enable = true;
    actionlint.enable = true;
    check-added-large-files.enable = true;
    check-merge-conflicts.enable = true;
    check-json.enable = true;
    check-shebang-scripts-are-executable.enable = true;
    check-symlinks.enable = true;
    check-toml.enable = true;
    check-yaml.enable = true;
    commitizen.enable = true;
    nil.enable = true;
    ripsecrets.enable = true;
    shellcheck.enable = true;

    # FIXME: `just lint`'s `-i`/`-L` flags mirror this ignore list by hand
    # (see justfile's `_statix`/`_deadnix`); keep both in sync.
    statix = {
      enable = true;
      settings.ignore = [
        # NOTE: generated by nixos-generate-config; not meant to be hand-edited or restyled.
        "modules/hosts/_hardware/*.nix"
      ];
    };

    # NOTE: module/perSystem args come from a fixed framework signature,
    # so unused ones are expected (same reasoning as nixpkgs callPackage).
    deadnix = {
      enable = true;
      settings.noLambdaPatternNames = true;
    };

    treefmt = {
      enable = true;
      packageOverrides.treefmt = treefmt;
    };

    nix-auto-follow =
      let
        ignoredInputs = [
          "vicinae"
        ];
        ignoreFlags = concatMapStringsSep " " (input: "--ignore ${input}") ignoredInputs;
      in
      {
        enable = true;
        name = "nix-auto-follow";
        description = "Check flake.lock inputs.*.follows are deduplicated via nix-auto-follow";
        entry = "${getExe autoFollow} --check ${ignoreFlags}";
        files = "^flake\\.lock$";
        pass_filenames = false;
      };
  };

  difftastic.enable = true;

  claude.code = {
    enable = true;
    mcpServers = {
      devenv = {
        type = "stdio";
        command = "devenv";
        args = [ "mcp" ];
        env = {
          DEVENV_ROOT = config.devenv.root;
        };
      };
      github = mkIf (secrets.GITHUB_PAT or null != null) {
        type = "http";
        url = "https://api.githubcopilot.com/mcp";
        headers.Authorization = "Bearer ${secrets.GITHUB_PAT}";
      };
    };
  };

}
