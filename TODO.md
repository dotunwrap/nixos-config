# TODO

Temporary scratch list of outstanding work. Not meant to be permanent --
fold items into real docs/issues once they're resolved, delete this file
once it's empty.

## Open

- **Add ability to choose preferred applications for foundational applications
  (starting with terminal and browser) per user per host.**: Users may want
  to use a different terminal or different browser from one another, and they
  may even want to use different ones on different machines themselves.
  We should be able to set it and have that be respected throughout other
  parts of the configuration where default applications, hotkeys to open
  these applications, etc are set. Should only ever be set once--keep it DRY.
- **Look for more test cases we could use**: We have nix-unit and devenv test-
  ing capabilities in this project. We should be utilizing this where is makes sense.
- **sops-nix secrets**: `sops-nix` is declared (`modules/secrets.nix`) but not
  wired up to any host/user yet -- configure actual secrets management for
  the project. Reference devenv's documentation for chances to leverage the
  secretspec capabilities. Ensure to properly mark the sops-nix related files as
  expected in .gitattributes
- **Further configure devenv**: Devenv is a powerful tool that we do not use effectively.
  We should make sure that we properly configure a concrete linting and formatting ruleset
  that is respected both in and outside of the devshell. All tooling in the devenv shell
  should also have their rules respected outside of it. We should be moving to test the
  new "Machines" feature to deploy remotely. We should further ensure that we are not missing
  git hooks that we would benefit from. We should configure the git and mergiraf integrations.
  We should configure any LSPs we use in this project. We should consider if we want to have
  some other profiles for various things such as CI/CD on GitHub or when we are in a Live ISO
  environment or something. We should ensure we are properly pushing outputs to and pulling
  outputs from my cachix store. We should also make sure the rest of the cachix stores are
  configured properly. We should use the changelog-merge integration and adopt a CHANGELOG.md
  (or CHANGES.md?). Ultimately we should just be taking advantage of every thing we can from
  this amazing tool.
- **Revisit and modernize CI/CD pipelines**: We should ensure that our CI
  is running all of the checks it can with proper usage of the cachix stores to cut down on
  cache misses and source builds in GH runners. If we are doing something inefficient, fix it.
  `modules/_data/caches.nix` is now the single source of truth for cache definitions (NixOS
  substituters, devenv's `cachix.pull`, and CI's `setup-nix` composite action all derive from
  it), but the rest of `.github/workflows/ci.yml` is still jankier than it should be -- steps
  get redefined per-job instead of once. Lean harder into `nix-github-actions`
  (`modules/github-actions.nix`) to generate more of the workflow itself rather than hand-writing
  duplicated YAML steps across jobs.
  We should implement a CD pipeline where on merge into `main` and have successful CI it prepares
  to deploy (using devenv?) to our remote machines (but should use GH environments or smth for each
  output to ensure we approve of the deploy first). Will need automated rollback on failure, though.
- **Configure conventional commit enforcement**: Adhering to the conventional commit structure,
  we should implement a tool to enforce this as a linting rule in CI.
- **Add in custom ISO output**: We should be generating a custom ISO for minimal NixOS installation
  media (no GUI--tty only) that has some basics for installing this configuration on a new machine
  pre-installed. Shouldn't really need to do the whole "magic wormholing back and forth a new GitHub
  SSH key for access to the monolisa font repo" anymore before we can install the OS. Don't ship with
  everything in the image, but bring the nice to haves. Make sure we build a new release in GH as CD
  whenever we merge into `main` with a diff in the image.
- **niri.nix vicinae Mesa workaround**: `modules/aspects/niri.nix`'s
  `vicinaeMesa` override (vicinae's glibc is older than the system's,
  breaking EGL/Vulkan) should be removed once
  [vicinae#2040](https://github.com/vicinaehq/vicinae/issues/2040) is
  resolved upstream.
- **den-diagram**: [github:denful/den-diagram](https://github.com/denful/den-diagram)
  is a companion flake (same author as `den`) that renders per-host aspect
  DAGs, a namespace graph, and fleet-wide views via mermaid. Worth adopting
  as its own task -- needs a new flake input plus a `modules/diagrams.nix`
  adapted to this repo's actual hosts/aspects (not the template's demo
  ones). `den.lib.capture.captureFleet {}` (already part of `den`, no extra
  input) is the lighter-weight alternative if full diagram rendering isn't
  worth it.
- **Consider dynamic documentation generation**: We could consider
  automatically generating documentation surrounding the configuration repo
  and project as a whole.
- **Dedupe the host definitions across repo**: We have multiple places where
  the list of hosts and their users are repeated across the repo (justfile, devenv, hosts.nix, etc)
  See if we can define a central location for the hosts list with the appropriate metadata in order to
  avoid needing to update so many locations when we deploy this configuration on a new host.
- **Remove nix-auth from actual config:** nix-auth only needs to be ran a handful of times, so we can
  probably remove that from the actually installed packages and just install it in devenv instead.\
  Make sure that we warn in the devenv shell if we detect a lack of auth token configured
- **Find if we can remove our scripts/\* from then project**: Audited — `scripts/resolve-nix-version.sh`
  is still needed. It resolves a matching `nixVersions.stable` version from `flake.lock`'s pinned nixpkgs
  rev in `ci.yml`'s `checks-matrix` job, which runs _before_ Nix is installed on the runner, so it can't
  `nix eval` the way the later cachix-resolution step in `.github/actions/setup-nix/action.yml` can. Removing
  it would mean rethinking the CI bootstrap approach entirely — left as the owner's call, not mechanical
  cleanup.
- **Consider combining our checks modules**: We should try to cut down on our multiple modules that define
  outputs for `checks`.
- **Consider breaking justfile into modules**: Our justfile is getting somewhat large in size. We
  may be at the point where we should break it up into submodules and just organize or orchestrate
  them all in the root justfile.

## Lastly

- **README.md & CLAUDE.md are stale**: they still documents the pre-dendritic layout
  Should be completely rewritten from scratch (both of them) but maintain general
  design-agnostic rules in the CLAUDE.md file and host/user purpose details in
  README.md and CLAUDE.md both at least. Also should include the diagram mermaid
  we implemented before.
- **Look for any new gaps in our justfile**: We may have some new recipes that would
  be useful to add with the new additions. Look to see if you can find any and report
  back ideas in a markdown file for me to look over.
