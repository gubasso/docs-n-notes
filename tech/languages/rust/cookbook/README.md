# Ship a Rust project — cookbook (TLDR)

One-file, top-to-bottom runbook to take a Rust crate from _repo + remote_ to _published,
branch-protected, CI-gated_. Copy-paste commands; each section footnotes the canonical spec that
owns the _why_.

> **Assumes:** a crate you can already `cargo build`, a git repo, and a GitHub remote (GitLab notes
> at the end). Replace `<owner>/<repo>` and `<crate>` throughout.
>
> This is a **cookbook** — it deliberately inlines snippets that live canonically in the specs it
> footnotes. That duplication is a sanctioned exception to the repo's single-source-of-truth rule.[^rule]
> For the reasoning behind any step, follow the footnote; if a snippet here ever disagrees with its
> footnoted spec, **the spec wins**.

**See also:** general recipes — project-bootstrap[^gen-bootstrap], release-workflow[^gen-release];
Rust specs distilled here — project-bootstrap-spec[^rs-bootstrap],
release-workflow-spec[^rs-release], cli-spec[^cli]; platform enforcement — branch-protection[^bp].

---

## 0. Prerequisites

```bash
cargo --version         # rustc + cargo installed
gh auth status          # GitHub CLI authenticated  (https://cli.github.com)
jq --version            # used by the branch-protection setup script
git remote -v           # origin points at your GitHub repo
```

## 1. Scaffold the crate[^rs-bootstrap]

Skip if the crate already exists.

```bash
cargo new <crate>            # binary  -> src/main.rs
# cargo new --lib <crate>    # library -> src/lib.rs
# cargo init                 # in an existing directory
```

Pin the toolchain so bare `cargo`, CI, and editors never drift — `rust-toolchain.toml` at the repo
root:[^nix-toolchain]

```toml
[toolchain]
channel = "stable"
components = ["rustfmt", "clippy"]
# targets = ["wasm32-unknown-unknown"]
```

## 2. Crate metadata — the publish gate[^crate-meta]

crates.io **rejects** a publish without `description` and a license. Set these in `Cargo.toml` now;
a dry run (§7) validates them with no token.

```toml
[package]
name = "<crate>"
version = "0.1.0"
edition = "2021"
description = "One-sentence summary of what the crate does."
license = "MIT OR Apache-2.0"
repository = "https://github.com/<owner>/<repo>"
readme = "README.md"
keywords = ["cli", "example", "tooling"]     # <=5, each <=20 chars
categories = ["command-line-utilities"]      # must match canonical slugs exactly
rust-version = "1.74"                         # MSRV

# Keep the .crate tarball lean (denylist; leading / anchors to package root).
exclude = [
    "/docs", "/.github", "/scripts",
    "/deny.toml", "/release-plz.toml", "/dist-workspace.toml",
    "/justfile", "/flake.nix", "/flake.lock", "/.pre-commit-config.yaml",
]
```

Ship the actual license files too (`LICENSE-MIT` + `LICENSE-APACHE` for the dual default) — an SPDX
`license` field does **not** auto-include them in the tarball.[^crate-meta]

## 3. Quality gates[^rs-gates]

Lints in `Cargo.toml`:[^cli-quality]

```toml
[lints.rust]
unsafe_code = "forbid"          # drop if you genuinely need unsafe

[lints.clippy]
pedantic         = { level = "warn", priority = -1 }
nursery          = { level = "warn", priority = -1 }
unwrap_used      = "warn"
expect_used      = "warn"
# restriction — catch scaffolding left behind
todo             = "deny"
dbg_macro        = "deny"
unimplemented    = "deny"
panic            = "deny"
wildcard_imports = "deny"
```

Dependency + license policy — `deny.toml` at the crate root:[^cli-quality]

```toml
[graph]
targets = []
all-features = true

[advisories]
vulnerability = "deny"
unmaintained = "warn"
unsound = "warn"
yanked = "warn"

[licenses]
allow = [
    "MIT",
    "Apache-2.0",
    "Apache-2.0 WITH LLVM-exception",
    "BSD-2-Clause",
    "BSD-3-Clause",
    "ISC",
    "Zlib",
    "Unicode-3.0",
    "Unicode-DFS-2016",
]

[bans]
multiple-versions = "warn"
deny = [
    { name = "openssl-sys" },  # prefer rustls for static builds
]

[sources]
unknown-registry = "deny"
unknown-git = "deny"
```

Run the gates locally:[^rs-gates]

```bash
cargo fmt --check
cargo clippy --all-targets --all-features -- -D warnings
cargo nextest run
cargo deny check
```

Pre-commit hooks — `.pre-commit-config.yaml`, then `pre-commit install`:[^gen-gates]

```yaml
repos:
  - repo: local
    hooks:
      - id: cargo-fmt
        name: cargo fmt --check
        entry: cargo fmt --check
        language: system
        types: [rust]
        pass_filenames: false
      - id: cargo-clippy
        name: cargo clippy
        entry: cargo clippy --all-targets --all-features -- -D warnings
        language: system
        types: [rust]
        pass_filenames: false
```

One command surface — `justfile`:[^gen-gates]

```just
default:
    @just --list

fmt:
    cargo fmt

lint:
    cargo clippy --all-targets --all-features -- -D warnings

test:
    cargo nextest run

check: fmt lint test
    cargo deny check
```

## 4. Local dev shell (Nix)[^nix-devshell]

A flake that reads `rust-toolchain.toml`, so local + CI share one toolchain and can't drift.
`flake.nix`:

```nix
{
  description = "rust dev shell (toolchain from rust-toolchain.toml)";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    rust-overlay.url = "github:oxalica/rust-overlay";
    rust-overlay.inputs.nixpkgs.follows = "nixpkgs";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    { self, nixpkgs, rust-overlay, flake-utils }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs {
          inherit system;
          overlays = [ (import rust-overlay) ];
        };
        toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
      in
      {
        devShells.default = pkgs.mkShell {
          packages = [
            toolchain
            pkgs.cargo-nextest
            pkgs.cargo-deny
            pkgs.cargo-audit
            pkgs.just
            pkgs.pre-commit
          ];
          shellHook = ''echo "rust dev shell ready (toolchain from rust-toolchain.toml)"'';
        };
      }
    );
}
```

`.envrc` (direnv auto-loads on `cd`), then lock + enter:

```bash
echo 'use flake' > .envrc
nix flake lock            # generate flake.lock — commit it
direnv allow              # or a one-off: nix develop
```

## 5. First CI workflow[^gen-ci]

`.github/workflows/ci.yml` reuses the flake and runs the gates on every push/PR. The **job name is
the status-check context** branch protection will require (§6) — name it deliberately.

```yaml
name: ci

on:
  push:
    branches: [develop, master]
  pull_request:

permissions:
  contents: read

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: DeterminateSystems/nix-installer-action@main
      - run: |
          nix develop -c bash -c '
            cargo fmt --check &&
            cargo clippy --all-targets --all-features -- -D warnings &&
            cargo nextest run --profile ci &&
            cargo deny check
          '
```

Optional CI test profile — `.config/nextest.toml` (a non-default profile is inert unless invoked
with `--profile ci`):[^cli-test]

```toml
[profile.ci]
fail-fast = false
retries = { backoff = "exponential", count = 2, delay = "1s", max-delay = "10s", jitter = true }
status-level = "fail"
final-status-level = "fail"
success-output = "never"
failure-output = "immediate-final"
```

## 6. Branch security[^bp]

Model: `develop` integrates (feature branches PR here); `master` mirrors releases (CI-only, linear
history); `v*` tags immutable.[^bp-model] Make sure `develop` exists first, then apply all three
rulesets + set the default branch with one script:[^bp]

```bash
git switch -c develop && git push -u origin develop   # if it doesn't exist yet

# REQUIRED_CHECKS must match the CI job name from §5 ("test").
OWNER_REPO=<owner>/<repo> REQUIRED_CHECKS="test" \
  "$DOCS_NOTES_REPO"/tech/tools/git/branch-protection/github/setup.sh
```

Then turn Actions on with write permission (the script can't via the API):[^bp-firstrun]

- **Settings → Actions → General →** allow Actions; **Workflow permissions → Read and write**; tick
  **Allow GitHub Actions to create and approve pull requests**.

Rulesets applied: `master` — no human writes, linear history, CI bypass actor, 1 review; `develop` —
1 review, no force-push/deletion; `v*` tags — no delete/update.[^bp] _(Solo project? Set
`required_approving_review_count` to `0` in the ruleset payloads, or merge via the bypass actor.)_

## 7. Release + publish[^rs-release]

Once per project, in order:[^rs-runbook]

1. **Validate metadata (no token):**

   ```bash
   cargo publish --dry-run
   cargo package --list
   ```

2. **First publish is manual** — Trusted Publishing attaches to a crate that already exists.[^oidc]
   Create a scoped token[^tokens] at <https://crates.io/settings/tokens> (endpoint `publish-new`,
   exact crate scope, shortest expiry), then:

   ```bash
   cargo login          # paste the token
   cargo publish
   ```

3. **Register the trusted publisher** at `https://crates.io/crates/<crate>/settings` → Trusted
   Publishing → Add:[^oidc]
   - Repository: `<owner>/<repo>`
   - **Workflow filename: `release-plz.yml`** (not `release.yml`)
   - Environment: blank

4. **Revoke the bootstrap token** at <https://crates.io/settings/tokens>. CI mints short-lived OIDC
   tokens from here on.[^tokens]

5. **Commit release automation.** `release-plz.toml`:[^rs-plz]

   ```toml
   # See https://release-plz.dev/docs/config for all options.
   [workspace]
   changelog_update = true   # maintain CHANGELOG.md from conventional commits
   release_always   = false  # release only when there is something to release
   publish          = true   # publish to crates.io on release-PR merge
   semver_check     = true   # gate public-API compatibility (libraries)
   ```

   `.github/workflows/release-plz.yml` — runs on `develop`, OIDC auth, **no
   `CARGO_REGISTRY_TOKEN`**:[^rs-plz]

   ```yaml
   name: release-plz

   on:
     push:
       branches: [develop]

   permissions:
     contents: write
     pull-requests: write
     id-token: write

   jobs:
     release-plz:
       runs-on: ubuntu-latest
       steps:
         - uses: actions/checkout@v4
           with:
             fetch-depth: 0
         - uses: release-plz/action@v0.5
           with:
             command: release-plz
           env:
             GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
   ```

   To also fast-forward `master` onto each release tag, add the `promote` job (a `needs:` job in the
   same run — a `GITHUB_TOKEN` tag push doesn't retrigger a standalone workflow).[^branch-model]

6. **(Optional) Enable "require trusted publishing"** on the crate once an OIDC release has
   succeeded — it rejects all token publishes.[^oidc]

**The everyday loop after setup:** merge a `feat:`/`fix:` to `develop` → release-plz opens a release
PR → merge it → release-plz tags `vX.Y.Z` and publishes over OIDC.[^branch-model]

## 8. (Optional) Prebuilt binaries — cargo-dist[^cargo-dist]

```bash
cargo install cargo-dist
dist init          # writes dist-workspace.toml + .github/workflows/release.yml
dist generate      # regenerate release.yml after editing dist-workspace.toml
```

`release.yml` (binaries) is a **separate** file from `release-plz.yml` (source publish) — never
merge them, and never register `release.yml` with the trusted publisher.[^cargo-dist]
`cargo binstall
<crate>` then works for free.

## 9. Day-2 — semver / yank / rollback[^semver]

```bash
cargo semver-checks check-release      # libraries: catch API breaks (release-plz runs this)
cargo yank --version 1.2.3             # stop new selections of a bad version
cargo yank --version 1.2.3 --undo      # reverse it
```

Published versions are **immutable** — never re-publish a number. "Rollback" = fix forward: patch on
`develop`, cut a new PATCH, optionally yank the bad one.[^semver]

## GitLab notes

Branch model, release-plz/OIDC, and metadata are identical. Differences:

- **Branch protection:**
  `PROJECT=group/project TIER=free "$DOCS_NOTES_REPO"/tech/tools/git/branch-protection/gitlab/setup.sh`
  (or `TIER=premium BOT_USER_ID=<id>`).[^bp]
- **Enable CI/CD**, let the pipeline write to `master`, set default branch `develop`.[^bp-firstrun]
- **OIDC:** crates.io Trusted Publishing supports gitlab.com (not self-hosted). The job requests a
  GitLab `id_token`, exchanges it via `CRATES_IO_ID_TOKEN`, then `cargo publish`; register the
  publisher for GitLab (project path + CI config filename).[^oidc]

## Footnotes

[^rule]: Cookbook duplication is a sanctioned exception to the repo's SoT/DRY rule — see
    [CLAUDE.md](../../../../CLAUDE.md) and
    [ADR-0002](../../../programming/design-decisions/cookbook-duplication-exception.md).

[^gen-bootstrap]: [General project-bootstrap](../../../programming/project-bootstrap/README.md) —
    the language-agnostic once-per-project recipe.

[^gen-release]: [General release-workflow](../../../programming/release-workflow/README.md) — the
    language-agnostic release principles.

[^rs-bootstrap]: [Rust project-bootstrap-spec](../project-bootstrap-spec/README.md) ·
    [toolchain & layout](../project-bootstrap-spec/00-toolchain-and-layout.md).

[^rs-release]: [Rust release-workflow-spec](../release-workflow-spec/README.md) — the full Rust
    release & publishing shelf.

[^cli]: [Rust cli-spec](../cli-spec/README.md) — detailed CLI crate structure, testing, and quality.

[^bp]: [branch-protection](../../../tools/git/branch-protection/README.md) — `github/setup.sh`, the
    ruleset payloads, and the GitLab path.

[^nix-toolchain]: [nix/03 — Rust toolchain in a devShell](../../../tools/nix/03-rust-toolchain.md).

[^crate-meta]: [release-workflow-spec/01 — Crate metadata](../release-workflow-spec/01-crate-metadata.md).

[^rs-gates]: [Rust project-bootstrap-spec/01 — Quality gates](../project-bootstrap-spec/01-quality-gates.md).

[^cli-quality]: [cli-spec/06 — Code quality](../cli-spec/06-testing-and-quality/code-quality.md) —
    the `deny.toml` and clippy restriction templates.

[^gen-gates]: [General project-bootstrap/04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md).

[^nix-devshell]: [nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md).

[^gen-ci]: [General project-bootstrap/05 — CI & release-readiness](../../../programming/project-bootstrap/05-ci-and-release-readiness.md).

[^cli-test]: [cli-spec/06 — Testing](../cli-spec/06-testing-and-quality/testing.md) — nextest
    profiles.

[^bp-model]: [Branch model & release-plz](../release-workflow-spec/00-branch-model-and-release-plz.md)
    · general [branch model](../../../programming/release-workflow/00-branch-model.md).

[^bp-firstrun]: [branch protection first-run enablement](../../../tools/git/branch-protection/first-run-enablement.md)

[^rs-runbook]: [release-workflow-spec/runbook](../release-workflow-spec/runbook.md) — the canonical
    ordered setup sequence.

[^oidc]: [release-workflow-spec/03 — Trusted Publishing / OIDC](../release-workflow-spec/03-trusted-publishing-oidc.md).

[^tokens]: [release-workflow-spec/02 — API tokens and scopes](../release-workflow-spec/02-api-tokens-and-scopes.md).

[^rs-plz]: [release-workflow-spec/04 — release-plz config & CI](../release-workflow-spec/04-release-plz-config.md).

[^branch-model]: [release-workflow-spec/00 — Branch model & `master` promotion](../release-workflow-spec/00-branch-model-and-release-plz.md).

[^cargo-dist]: [release-workflow-spec/05 — Binary distribution (cargo-dist)](../release-workflow-spec/05-binary-distribution-cargo-dist.md).

[^semver]: [release-workflow-spec/07 — SemVer, yank, rollback](../release-workflow-spec/07-semver-yank-rollback.md).
