# Bash Program Release & Distribution Workflow

> $bash $shell $release $packaging $github-actions $aur $semver

A lean, opinionated workflow for releasing and distributing a Bash CLI on
Linux. Targets a single-maintainer pure-Bash project (no compiled
artifacts, "noarch" payload). Scales down to "tag → tarball → GitHub
Release → installer + AUR" and up to deb/rpm/Homebrew when needed.

<!-- toc -->

- [When this applies](#when-this-applies)
- [The lean default path](#the-lean-default-path)
- [1. Versioning — single source of truth](#1-versioning--single-source-of-truth)
- [2. Conventional commits + changelog](#2-conventional-commits--changelog)
- [3. Makefile — follow GNU coding standards](#3-makefile--follow-gnu-coding-standards)
- [4. CI release workflow](#4-ci-release-workflow)
- [5. End-user install methods](#5-end-user-install-methods)
  - [5.1 `install.sh` curl one-liner](#51-installsh-curl-one-liner)
  - [5.2 AUR package](#52-aur-package)
  - [5.3 `.deb` / `.rpm` via nfpm (later)](#53-deb--rpm-via-nfpm-later)
  - [5.4 What to skip (for now)](#54-what-to-skip-for-now)
- [The release ritual](#the-release-ritual)
- [Files to add — checklist](#files-to-add--checklist)
- [Alternatives — when to pick them](#alternatives--when-to-pick-them)
- [References](#references)

<!-- tocstop -->

## When this applies

- Pure Bash (or mostly Bash) CLI tool, no compiled artifacts.
- Distributed to Linux hosts.
- Currently installed via `git clone && make install`, and you want
  something leaner/safer for end users.
- Single maintainer or small team — no need for GoReleaser-class
  monoliths.

## The lean default path

**Tag → tarball → GitHub Release → `install.sh` + AUR.**

Five moving parts:

1. `VERSION` file as single source of truth.
2. Conventional commits + `git-cliff` for `CHANGELOG.md`.
3. `Makefile` that respects `PREFIX`/`DESTDIR` (GNU conventions) and
   has a `dist` target.
4. GitHub Actions workflow triggered on `v*` tag → builds tarball,
   attaches `SHA256SUMS` + SLSA provenance, publishes release.
5. End-user install via curl-piped `install.sh` (with checksum
   verification), AUR PKGBUILD, optionally `.deb`/`.rpm` later.

## 1. Versioning — single source of truth

Add a `VERSION` file at the repo root containing one line:

```
0.1.0
```

This is what GNU coding standards and tools like `nfpm` expect.

Two equivalent ways to expose it from the binary's `version` subcommand:

- **Ship `VERSION` alongside the lib** — `make install` copies it into
  `$(datadir)/<tool>/VERSION`; the dispatcher cats it. Zero build step.
- **Placeholder substitution at install time** — script contains
  `TOOL_VERSION="__TOOL_VERSION__"`, and `make install` runs
  `sed -i "s/__TOOL_VERSION__/$$(cat VERSION)/"` on the installed copy.
  Cleaner for tarball and git users alike.

For developer builds (running from a git checkout), fall back to
`git describe --tags --dirty --always` so `version` is always
informative.

Follow [SemVer](https://semver.org/) for the numbering.

## 2. Conventional commits + changelog

Use [Conventional Commits](https://www.conventionalcommits.org/) and
enforce them with a `commitlint` pre-commit hook.

Generate `CHANGELOG.md` with [git-cliff](https://git-cliff.org/) — a
single static Rust binary, no Node/Python deps, fast on large histories.
Config lives in `cliff.toml`; use the Keep-a-Changelog preset.

**Why git-cliff over release-please:**

- release-please is GitHub/Node-centric and creates "release PRs" that
  don't fit a Bash project well.
- git-cliff runs anywhere, is configured by a single file, and you tag
  manually when you actually want a release.

## 3. Makefile — follow GNU coding standards

The single highest-leverage change. Per the
[GNU Coding Standards on Directory Variables](https://www.gnu.org/prep/standards/html_node/Directory-Variables.html)
and [DESTDIR](https://www.gnu.org/prep/standards/html_node/DESTDIR.html):

```make
PREFIX     ?= /usr/local
DESTDIR    ?=
bindir     ?= $(PREFIX)/bin
libdir     ?= $(PREFIX)/lib/<tool>
datadir    ?= $(PREFIX)/share/<tool>
sysconfdir ?= $(PREFIX)/etc

INSTALL ?= install

install:
	$(INSTALL) -d "$(DESTDIR)$(bindir)" "$(DESTDIR)$(libdir)" "$(DESTDIR)$(datadir)"
	$(INSTALL) -m 0755 bin/<tool> "$(DESTDIR)$(bindir)/"
	# ... etc
```

Every install path uses `$(DESTDIR)$(prefix-var)`. This is the
contract every packaging tool (`nfpm`, AUR `PKGBUILD`, `.deb`/`.rpm`
post-install scripts) assumes.

Keep the `~/.local` ergonomics by exposing a convenience target:

```make
user-install:
	$(MAKE) PREFIX="$$HOME/.local" install
```

Add a `dist` target that produces a reproducible tarball:

```make
VERSION := $(shell cat VERSION)
DIST    := <tool>-$(VERSION)

dist:
	git archive --format=tar.gz --prefix=$(DIST)/ -o $(DIST).tar.gz HEAD
	sha256sum $(DIST).tar.gz > $(DIST).tar.gz.sha256
```

`git archive` produces a clean tarball from the committed tree — no
`.git`, no work-clones, no temp files.

Also provide a symmetric `uninstall` target.

## 4. CI release workflow

`.github/workflows/release.yml` — trigger on `v*` tag push:

```yaml
on:
  push:
    tags: ['v*']

permissions:
  contents: write        # for gh release create
  id-token: write        # for SLSA provenance / Sigstore OIDC
  attestations: write    # for GitHub Artifact Attestations

jobs:
  test:
    uses: ./.github/workflows/ci.yml  # shellcheck, shfmt, bats

  release:
    needs: test
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0          # git-cliff needs full history

      - run: make dist

      - uses: orhun/git-cliff-action@v4
        with:
          args: --latest --strip header
        # writes release_notes.md

      - uses: actions/attest-build-provenance@v2
        with:
          subject-path: '<tool>-*.tar.gz'

      - run: |
          gh release create "${GITHUB_REF_NAME}" \
            --title "${GITHUB_REF_NAME}" \
            --notes-file release_notes.md \
            <tool>-*.tar.gz <tool>-*.tar.gz.sha256
        env:
          GH_TOKEN: ${{ github.token }}
```

**Use GitHub's built-in
[`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance)
rather than rolling your own cosign workflow** — free for public repos,
generates SLSA L3 provenance, and signs through the Sigstore
public-good instance keylessly via GitHub's OIDC token. One step, no
key management. Users verify with `gh attestation verify`.

## 5. End-user install methods

In priority order:

### 5.1 `install.sh` curl one-liner

Primary path — works everywhere. README shows:

```bash
curl -fsSL https://raw.githubusercontent.com/<user>/<tool>/main/install.sh | bash
```

The script **must**:

1. Discover the latest tag via the GitHub Releases API.
2. Download the tarball **and** its `.sha256`.
3. **Verify the checksum before extracting.** This is the only
   legitimate complaint about the `curl|bash` pattern — address it.
4. Unpack to a temp dir.
5. Run `make install` (default `PREFIX=$HOME/.local`, overridable via
   env var).

Optionally also verify with `gh attestation verify` when the user has
`gh` installed.

Sketch:

```bash
#!/usr/bin/env bash
set -euo pipefail

REPO="<user>/<tool>"
PREFIX="${PREFIX:-$HOME/.local}"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

TAG="$(curl -fsSL "https://api.github.com/repos/$REPO/releases/latest" \
       | grep -oP '"tag_name":\s*"\K[^"]+')"

cd "$TMP"
curl -fsSLO "https://github.com/$REPO/releases/download/$TAG/<tool>-${TAG#v}.tar.gz"
curl -fsSLO "https://github.com/$REPO/releases/download/$TAG/<tool>-${TAG#v}.tar.gz.sha256"
sha256sum -c "<tool>-${TAG#v}.tar.gz.sha256"

tar -xzf "<tool>-${TAG#v}.tar.gz"
cd "<tool>-${TAG#v}"
make PREFIX="$PREFIX" install
```

### 5.2 AUR package

On Arch, publish two packages per the
[ArchWiki VCS package guidelines](https://wiki.archlinux.org/title/VCS_package_guidelines):

- `<tool>` — pins to the latest tag,
  `source=("$pkgname-$pkgver.tar.gz::https://github.com/.../archive/v$pkgver.tar.gz")`,
  with `sha256sums` from your published `SHA256SUMS`.
- `<tool>-git` — VCS variant tracking `main`, with the standard
  `pkgver()` function and `-git` suffix.

Because the Makefile now respects `DESTDIR`/`PREFIX`, `package()` is
one line:

```bash
package() {
  cd "$pkgname-$pkgver"
  make DESTDIR="$pkgdir" PREFIX=/usr install
}
```

Keep the PKGBUILDs in the project repo under
`packaging/aur/<tool>/PKGBUILD` and `packaging/aur/<tool>-git/PKGBUILD`,
then `git subtree push` to the corresponding AUR repos at release time.

### 5.3 `.deb` / `.rpm` via nfpm (later)

[nfpm](https://github.com/goreleaser/nfpm) — single static Go binary,
single YAML config, zero Ruby/Python deps (unlike `fpm`). Add it as a
second job in the release workflow **only when you actually have
non-Arch users asking**. nfpm is the modern lean choice; fpm is heavier
and Ruby-based.

### 5.4 What to skip (for now)

- **Homebrew tap** — Mac-centric, low ROI for a Linux-only tool.
- **Nix flake / nixpkgs** — only if a user requests it.
- **bpkg / basher / eget** — low adoption among end users.
- **Self-hosted apt/yum repo** (Cloudsmith, packagecloud, GitHub Pages
  + `apt-ftparchive`) — only when enterprise users refuse `curl | bash`.

## The release ritual

Once everything above is in place, cutting a release is:

```bash
git-cliff --bump -o CHANGELOG.md          # bump version + write changelog
NEW=$(git-cliff --bumped-version)         # e.g. v0.2.0
printf '%s\n' "${NEW#v}" > VERSION
git commit -am "chore(release): ${NEW}"
git tag -s "${NEW}" -m "${NEW}"           # signed annotated tag
git push --follow-tags                    # CI takes it from here
```

CI builds the tarball, attaches `SHA256SUMS`, attaches SLSA provenance,
publishes the release with generated notes, and the `install.sh`
immediately picks it up.

## Files to add — checklist

| Path | Purpose |
|---|---|
| `VERSION` | One line, e.g. `0.1.0`. Source of truth. |
| `cliff.toml` | git-cliff config (Keep-a-Changelog preset). |
| `CHANGELOG.md` | Generated by git-cliff at each release; committed. |
| `install.sh` | curl-piped installer: discover latest tag → download tarball + `.sha256` → verify → install to `~/.local` by default. |
| `.github/workflows/release.yml` | Tag-triggered: test → `make dist` → git-cliff notes → attest-build-provenance → `gh release create`. |
| `packaging/aur/<tool>/PKGBUILD` | Stable-release PKGBUILD. |
| `packaging/aur/<tool>-git/PKGBUILD` | VCS variant tracking `main`. |
| `packaging/nfpm.yaml` *(later)* | Single config that emits both `.deb` and `.rpm`. |
| Makefile edits | Add `PREFIX`/`DESTDIR`/`bindir`/`libdir`/`datadir`; add `dist:`; rewrite `install:`/`uninstall:` to use `$(DESTDIR)$(bindir)` etc. |
| Dispatcher script edit | Implement `version` subcommand via `VERSION` file or `__TOOL_VERSION__` placeholder; fall back to `git describe` in dev. |
| `README.md` / `docs/INSTALL.md` edits | New "Install" section: curl one-liner → AUR → from source. |

## Alternatives — when to pick them

- **[release-please](https://github.com/googleapis/release-please)
  instead of git-cliff + manual tag** — pick when you want every
  release proposed as a PR you merge to ship. Heavier, GitHub-locked,
  Node-based. Fine for SaaS, overkill for a single-maintainer Bash CLI.
- **GoReleaser-style monolithic config** — only worth it once shipping
  deb + rpm + apk + arch + homebrew + docker simultaneously. For a
  Bash project, hand-written workflow + nfpm stays leaner.
- **Self-hosted apt/yum repo** — only when enterprise users refuse
  `curl | bash` *and* refuse `.deb`/`.rpm` downloads.

## References

- [GNU Coding Standards — Directory Variables](https://www.gnu.org/prep/standards/html_node/Directory-Variables.html)
- [GNU Coding Standards — DESTDIR](https://www.gnu.org/prep/standards/html_node/DESTDIR.html)
- [Semantic Versioning](https://semver.org/)
- [Keep a Changelog](https://keepachangelog.com/)
- [Conventional Commits](https://www.conventionalcommits.org/)
- [git-cliff](https://git-cliff.org/) — [repo](https://github.com/orhun/git-cliff)
- [git-cliff vs release-please](https://medium.com/@toniomasotti/git-cliff-96449950db48)
- [release-please](https://github.com/googleapis/release-please)
- [`gh release create` reference](https://cli.github.com/manual/gh_release_create)
- [`softprops/action-gh-release`](https://github.com/softprops/action-gh-release)
- [`actions/attest-build-provenance`](https://github.com/actions/attest-build-provenance)
- [Sigstore — verifying GitHub Artifact Attestations with cosign](https://blog.sigstore.dev/cosign-verify-bundles/)
- [Cycode — keyless signing with Sigstore and CI](https://cycode.com/blog/securing-artifacts-keyless-signing-with-sigstore-and-ci-mon/)
- [Chef — 5 ways to deal with `curl|bash` installer problems](https://www.chef.io/blog/5-ways-to-deal-with-the-install-sh-curl-pipe-bash-problem)
- [checksum.sh — verify every install script](https://checksum.sh/)
- [arp242 — Curl-to-shell isn't so bad](https://www.arp242.net/curl-to-sh.html)
- [ArchWiki — VCS package guidelines](https://wiki.archlinux.org/title/VCS_package_guidelines)
- [ArchWiki — AUR submission guidelines](https://wiki.archlinux.org/title/AUR_submission_guidelines)
- [nfpm](https://github.com/goreleaser/nfpm)
- [fpm](https://fpm.readthedocs.io/en/latest/getting-started.html)
- [meson — Creating releases (VERSION file pattern)](https://mesonbuild.com/Creating-releases.html)
