# Bloat & Bugs Audit

Scope: `modules/`, `justfile`, `devenv.nix`, `flake.nix`, `.github/workflows/`
(plus `.github/actions/`, `scripts/`, `assets/`, `README.md`/`TODO.md` where
relevant). Read-only pass; `statix`/`deadnix` were also run directly and came
back clean, so everything below is semantic/structural rather than
syntactic. All claims involving runtime option values were checked with
`nix eval`, not inferred from reading alone.

Two issues this repo already tracks elsewhere are intentionally **not**
repeated here in detail:

- `nix-auth` living in `modules/defaults.nix`'s `home.packages` instead of
  devenv-only (TODO.md: "Remove nix-auth from actual config").
- `justfile`'s hardcoded `hosts := [...]` and `devenv.nix`'s hardcoded
  `fleet` both duplicating `modules/hosts.nix`'s host list (TODO.md: "Dedupe
  the host definitions across repo").

A handful of other TODO.md items (combining the `checks`-producing modules,
removing `scripts/resolve-nix-version.sh`, auditing `den`'s primary-user
battery, splitting up `justfile`, tidying the repo root) cover ground
adjacent to a couple of findings below; those are noted inline with a
pointer rather than re-explained.

## Bugs

### 1. `kaiousei` is missing `networking.networkmanager.enable` and `time.timeZone` — and it's the primary machine

Every other NixOS host explicitly sets these four things in its entry
point:

| host                        | `hostName` | `networkmanager.enable` | `time.timeZone` | `i18n.defaultLocale` |
| --------------------------- | ---------- | ----------------------- | --------------- | -------------------- |
| `chikyuu.nix:81-82,106-107` | ✓          | ✓                       | ✓               | ✓                    |
| `europa.nix:12-13,24-25`    | ✓          | ✓                       | ✓               | ✓                    |
| `meiousei.nix:52-53,56-57`  | ✓          | ✓                       | ✓               | ✓                    |
| `suisei.nix:16-17,30-31`    | ✓          | ✓                       | ✓               | ✓                    |
| `kaiousei.nix`              | —          | —                       | —               | —                    |

`modules/hosts/kaiousei.nix` sets none of the four. Verified with `nix eval`
against the real built config:

```
networking.hostName            = "kaiousei"   (OK — see finding 2, a battery supplies this)
networking.networkmanager.enable = false      (every other host explicitly sets true)
time.timeZone                  = null          (every other host explicitly sets "America/New_York")
i18n.defaultLocale             = "en_US.UTF-8" (harmless: this is nixpkgs' own default — see finding 3)
```

So on `kaiousei` — README.md's described "main machine" — there is no
NetworkManager and the clock is on UTC. This looks like a genuine oversight
(most likely: `kaiousei.nix` was written after someone decided the
hostname/locale boilerplate was unnecessary, without noticing `networkmanager`
and `timeZone` have no such free ride — see finding 2/3 for why only two of
the four are actually redundant).

**Recommendation:** add the missing two lines to `modules/hosts/kaiousei.nix`
to unblock the immediate bug, but better: hoist `networking.networkmanager.enable
= lib.mkDefault true;` and `time.timeZone = lib.mkDefault "America/New_York";`
into the shared `den.default`/nixos block in `modules/defaults.nix` (every
host wants both, and `lib.mkDefault` still lets a future host override). That
also deletes the now-redundant explicit lines from the other four hosts and
makes this class of gap structurally impossible on the next new host.

### 2. Redundant `networking.hostName` assignments — a `den` battery already handles it

`modules/defaults.nix:56` includes `den.batteries.hostname` in every host's
baseline (`den.default.includes`). This battery already derives
`networking.hostName` from the host's own name — proven by `kaiousei.nix`,
which never sets `hostName` anywhere and still resolves to
`networking.hostName = "kaiousei"` (checked via `nix eval`).

Despite that, four hosts redundantly hardcode the exact same string the
battery would already produce:

- `modules/hosts/chikyuu.nix:81` — `hostName = "chikyuu";`
- `modules/hosts/europa.nix:12` — `hostName = "europa";`
- `modules/hosts/meiousei.nix:52` — `hostName = "meiousei";`
- `modules/hosts/suisei.nix:16` — `hostName = "suisei";`

**Recommendation:** delete all four lines; `den.batteries.hostname` already
covers it (confirmed no behavioral change for any of the four hosts, since
the hardcoded value and the battery-derived value are identical).

### 3. Redundant `i18n.defaultLocale = "en_US.UTF-8"` — matches the nixpkgs default exactly

`nix eval .#nixosConfigurations.<host>.options.i18n.defaultLocale.default`
returns `"en_US.UTF-8"` — i.e. nixpkgs' own intrinsic default, not something
any module in this repo sets. The four lines below add zero behavior:

- `modules/hosts/chikyuu.nix:107`
- `modules/hosts/europa.nix:25`
- `modules/hosts/meiousei.nix:57`
- `modules/hosts/suisei.nix:31`

**Recommendation:** delete them. (Unlike `networkmanager`/`timeZone`, this
one isn't a gap on `kaiousei` — it's dead weight on the other four.)

## Redundancy / copy-paste bloat

### 4. `chikyuu.nix` and `meiousei.nix` duplicate an entire v4l2loopback/ffado block verbatim

`modules/hosts/chikyuu.nix:26-38` and `modules/hosts/meiousei.nix:29-49`
both contain byte-identical:

```nix
boot = {
  kernelModules = [ "kvm-amd" "v4l2loopback" ];
  extraModulePackages = with pkgs.linuxPackages; [ v4l2loopback ];
  extraModprobeConfig = ''
    options v4l2loopback devices=1 video_nr=10 card_label="VirtualCam" exclusive_caps=1
  '';
};
...
environment.systemPackages = [ pkgs.ffado ];
```

Both hosts already share `den.aspects.gaming`/`den.aspects.dwm`/
`den.aspects.development` via `includes`, so there's an obvious home for
this. **Recommendation:** extract this block into a new small aspect (e.g.
`den.aspects.amd-gaming-desktop` or similar) included by both `chikyuu` and
`meiousei`, or at minimum fold it into `den.aspects.gaming.nixos` if every
current and future gaming host needs the virtual-cam/FireWire-audio setup.

Related, smaller case of the same pattern: both hosts also independently set
the identical `hardware.graphics = { enable = true; enable32Bit = true; };`
(`chikyuu.nix:21-24`, `meiousei.nix:17-20`) — graphics acceleration is
basically a hard requirement of `den.aspects.gaming`, so this is a reasonable
candidate to move into that aspect too.

### 5. `gabby` and `nia` duplicate an entire `programs.ssh` block verbatim

`modules/users/gabby/default.nix:73-95` and `modules/users/nia.nix:69-91`
are a byte-identical 21-line `programs.ssh` configuration (every setting
under `"*"` and the `"github.com"` host block, down to
`IdentityFile = "~/.ssh/github_ed25519"` — note both users apparently share
the same SSH key filename convention, which is itself worth double-checking
since they're different people with presumably different keys).

Both user aspects already route through `den.batteries.primary-user`
(TODO.md's "Audit lack of use of primary user battery" item tracks a
related but narrower concern — whether `den`'s battery already covers the
`homeManager.classes` boilerplate in `hosts.nix`; it doesn't currently cover
this SSH duplication). **Recommendation:** either fold this `programs.ssh`
block into `den.batteries.primary-user`'s `homeManager` output (if it's
meant to be universal baseline, the same way `modules/defaults.nix` holds
other cross-user defaults), or add a small shared `den.batteries.ssh-defaults`
battery parameterized by nothing (both users currently want the exact same
settings) so a future third user doesn't re-paste it a third time.

## Dead code

### 6. `modules/users/gabby/_zen/bookmarks.nix` is never imported

```nix
# TODO: Configure bookmarks
{ }
```

`modules/users/gabby/_zen/default.nix:1-15` imports `policies.nix`,
`settings.nix`, `extensions.nix`, `search-engines.nix`, and `shortcuts.nix`
— but never `bookmarks.nix`. It's an orphaned stub nobody references.
`deadnix`/`statix` don't catch this because it's a structurally valid,
unreferenced file, not unused code _within_ a file.

**Recommendation:** either wire it in (`profiles.default.bookmarks = import
./bookmarks.nix;`, if the zen-browser HM module has such an option) or
delete the file until the TODO is actually acted on.

### 7. 12 of 15 wallpapers in `assets/wallpapers/` are unused (~66 MB of ~90 MB)

Only three files are referenced anywhere in `modules/`
(`stephen_njoto.png`, `anyb-girl.png`, `bubbles.jpg` — via
`den.batteries.wallpaper` calls in `modules/users/gabby/default.nix:26,30,34`
and `modules/users/nia.nix:29,33`):

```
$ grep -rn "assets/wallpapers" modules/
modules/users/nia.nix:          anyb-girl.png, bubbles.jpg
modules/users/gabby/default.nix: stephen_njoto.png, anyb-girl.png (x2)
```

Unreferenced files sitting in the repo (sizes via `du -h`):

```
17M  salzburg.png
16M  poly.png
11M  smile.png
11M  notch_of_the_white_mountains.jpeg
5.5M tloz.jpg
2.8M albano.jpg
840K bay.jpeg
804K made-in-abyss.jpg
784K cinn.png
356K girl-on-chair.png
112K gruvbox_pixels.png
72K  miku.jpg
```

These are presumably leftovers from past wallpaper choices (or candidates
nobody committed to). They cost real repo-clone/checkout size and, since
this is a `git` repo (not Git LFS), they're permanently in history even if
deleted now.

**Recommendation:** either wire the ones still wanted into a
`den.batteries.wallpaper` call, or `git rm` the rest. If keeping some around
as "options to pick from later" is intentional, consider moving them out of
the repo entirely (a separate scratch location) so they don't bloat every
clone of this config.

## Doc-rot / stale comments

### 8. `modules/hosts.nix`'s comment points at a `TODO.md` entry that doesn't exist

```nix
# NOTE: no users.nia here; see TODO.md.
europa.intoAttr = [ ];
```

`TODO.md` has no mention of `europa` or `nia` anywhere (`grep -n -i
"europa\|nia" TODO.md` returns nothing). `README.md` does correctly
document that `nia` isn't on `europa`, so the fact itself is fine — the
comment's pointer to `TODO.md` is simply wrong/stale (maybe the explanation
used to live there and was cleaned up without updating the cross-reference,
or it was meant to point at `README.md` instead).

**Recommendation:** fix the comment to point at `README.md` (where the
host/user mapping is actually documented), or drop the pointer entirely —
the comment is self-explanatory without it.

## Minor / lower-priority notes

- `modules/hosts/chikyuu.nix:83-104` and `modules/hosts/suisei.nix:18-27`
  both wire up the identical
  `networking.nftables.enable` + `firewall.trustedInterfaces =
[config.services.tailscale.interfaceName]` + `firewall.allowedUDPPorts =
[config.services.tailscale.port]` + `systemd.services.tailscaled.serviceConfig.Environment
= ["TS_DEBUG_FIREWALL_MODE=nftables"]` pattern. Unlike finding 4, this
  isn't dead redundancy (`europa`/`meiousei` don't use nftables as their
  firewall backend, so they genuinely don't need it) — but if a third host
  ever opts into nftables, this is worth factoring into a small
  `den.batteries.nftables-tailscale` helper rather than copy-pasting a third
  time.
- `.github/actions/setup-nix/action.yml`'s "Setup SSH" step writes
  `~/.ssh/id_rsa` from `inputs.ssh-private-key` unconditionally, even though
  that secret is empty on fork PRs (GitHub doesn't pass secrets to
  fork-sourced workflow runs). The step itself won't fail on an empty
  secret, but any job step that actually needs the private `monolisa`
  input will fail further downstream with a less obvious SSH auth error
  instead of a clear "no secret available on fork PRs" message. Not a
  correctness bug in this repo's own CI (it's never run from a fork), but
  worth a comment if that ever changes.
