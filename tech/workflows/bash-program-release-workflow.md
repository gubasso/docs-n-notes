# Bash Program Release & Distribution Workflow

> $bash $shell $release $packaging $github-actions $aur $obs $opensuse $rpm $deb $semver

A lean, opinionated workflow for releasing and distributing a Bash CLI on
Linux. Targets a single-maintainer pure-Bash project (no compiled
artifacts, "noarch" payload). One source of truth (a signed `v*` git
tag) fans out to: a `curl | bash` installer, an AUR package, and the
openSUSE Build Service (OBS) for `.rpm`/`.deb` across openSUSE, Fedora,
Debian, and Ubuntu.

<!--TOC-->

- [When this applies](#when-this-applies)
- [The lean default path](#the-lean-default-path)
- [1. Versioning — single source of truth](#1-versioning--single-source-of-truth)
- [2. Conventional commits + changelog](#2-conventional-commits--changelog)
- [3. Makefile — follow GNU coding standards](#3-makefile--follow-gnu-coding-standards)
- [4. CI release workflow](#4-ci-release-workflow)
- [5. End-user install methods](#5-end-user-install-methods)
  - [5.1 `install.sh` curl one-liner](#51-installsh-curl-one-liner)
  - [5.2 AUR package](#52-aur-package)
  - [5.3 OBS — openSUSE, Fedora, Debian, Ubuntu](#53-obs--opensuse-fedora-debian-ubuntu)
    - [5.3.1 One-time OBS setup](#531-one-time-obs-setup)
    - [5.3.2 Files to commit to the OBS package](#532-files-to-commit-to-the-obs-package)
    - [5.3.3 CI trigger from GitHub Actions](#533-ci-trigger-from-github-actions)
    - [5.3.4 End-user install](#534-end-user-install)
  - [5.4 What to skip (for now)](#54-what-to-skip-for-now)
- [The release ritual](#the-release-ritual)
- [Files to add — checklist](#files-to-add--checklist)
- [Alternatives — when to pick them](#alternatives--when-to-pick-them)
- [References](#references)

<!--TOC-->

## When this applies

- Pure Bash (or mostly Bash) CLI tool, no compiled artifacts.
- Distributed to Linux hosts.
- Currently installed via `git clone && make install`, and you want
  something leaner/safer for end users.
- Single maintainer or small team — no need for GoReleaser-class
  monoliths.

## The lean default path

**Tag → tarball → GitHub Release → `install.sh` + AUR + OBS.**

Six moving parts:

1. `VERSION` file as single source of truth.
1. Conventional commits + `git-cliff` for `CHANGELOG.md`.
1. `Makefile` that respects `PREFIX`/`DESTDIR` (GNU conventions) and
   has a `dist` target.
1. GitHub Actions workflow triggered on `v*` tag → builds tarball,
   attaches `SHA256SUMS` + SLSA provenance, publishes release, triggers
   the OBS service run.
1. AUR PKGBUILDs (stable + `-git`) pushed via `git subtree` from
   `packaging/aur/`.
1. OBS project (`home:<user>:<tool>`) pulls the same `v*` tag via
   `obs_scm` and emits signed `.rpm`/`.deb` repos for openSUSE
   Tumbleweed/Leap, Fedora, Debian, Ubuntu. End-user install: curl
   one-liner, AUR (`yay`/`paru`), or `zypper ar` / `dnf config-manager` / `apt` against the OBS-hosted repo.

## 1. Versioning — single source of truth

Add a `VERSION` file at the repo root containing one line:

```
0.1.0
```

This is what GNU coding standards and packaging tools (OBS
`set_version`, `nfpm`, RPM `%autosetup`) expect.

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

      - name: Trigger OBS service run
        env:
          OBS_TOKEN: ${{ secrets.OBS_TOKEN }}
        run: |
          curl --fail-with-body -X POST \
            -H "Authorization: Token ${OBS_TOKEN}" \
            "https://api.opensuse.org/trigger/runservice?project=home:<user>:<tool>&package=<tool>"
```

The OBS trigger uses a per-package scoped token (see §5.3.1) — endpoint
on `api.opensuse.org`, literal header `Authorization: Token`, never
`Bearer`. `--fail-with-body` surfaces OBS errors so the Action doesn't
silently succeed when OBS rejects the request.

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
1. Download the tarball **and** its `.sha256`.
1. **Verify the checksum before extracting.** This is the only
   legitimate complaint about the `curl|bash` pattern — address it.
1. Unpack to a temp dir.
1. Run `make install` (default `PREFIX=$HOME/.local`, overridable via
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

### 5.3 OBS — openSUSE, Fedora, Debian, Ubuntu

The [openSUSE Build Service](https://openbuildservice.org/) builds
`.rpm` and `.deb` from a single `.spec` + `debian.*` set and **hosts
the signed repos** at
`https://download.opensuse.org/repositories/home:<user>:<tool>/<distro>/`.
End users add the repo once; `zypper` / `dnf` / `apt` handle updates
from then on.

OBS pulls source from your `v*` tag via
[`obs_scm`](https://github.com/openSUSE/obs-service-tar_scm), so the
GitHub tag stays the single source of truth — CI never uploads
tarballs to OBS. The CI step in §4 only posts a one-line `curl` that
tells OBS "the tag moved, re-run services" — OBS does the rest.

#### 5.3.1 One-time OBS setup

Do these **once** in the web UI at
[build.opensuse.org](https://build.opensuse.org/) (or via
[`osc`](https://en.opensuse.org/openSUSE:OSC) — install
`osc` locally first):

1. **Create the project.** `home:<user>` is auto-created on first
   login; create a sub-project `home:<user>:<tool>` to isolate this
   tool's repos and metadata.

1. **Enable target repositories** in `_meta`. From the WebUI use
   *Repositories → Add from a Distribution*; from the CLI use
   `osc meta prj -e home:<user>:<tool>` and paste the XML below.
   Always cross-check current repo names in the WebUI picker — Leap
   versions move and Fedora numbers bump.

   ```xml
   <project name="home:<user>:<tool>">
     <title><tool></title>
     <description>Pure-Bash CLI, packaged for multiple distros.</description>
     <person userid="<user>" role="maintainer"/>

     <repository name="openSUSE_Tumbleweed">
       <path project="openSUSE:Factory" repository="snapshot"/>
       <arch>x86_64</arch>
     </repository>
     <repository name="15.6">
       <path project="openSUSE:Leap:15.6" repository="standard"/>
       <arch>x86_64</arch>
     </repository>
     <repository name="Fedora_41">
       <path project="Fedora:41" repository="standard"/>
       <arch>x86_64</arch>
     </repository>
     <repository name="Debian_12">
       <path project="Debian:12" repository="standard"/>
       <arch>x86_64</arch>
     </repository>
     <repository name="xUbuntu_24.04">
       <path project="Ubuntu:24.04" repository="universe"/>
       <arch>x86_64</arch>
     </repository>
   </project>
   ```

   For a `noarch` package, one `x86_64` per repo is enough — OBS
   builds the noarch artifact once per repo and serves it for every
   architecture.

1. **Create the package container.**

   ```bash
   osc meta pkg -e home:<user>:<tool> <tool>
   ```

1. **Create a scoped trigger token** (a leaked token can then only
   re-run *this* package's services, not your whole account):

   ```bash
   osc token --create --operation runservice home:<user>:<tool> <tool>
   ```

   Store the secret string as the GitHub Actions secret `OBS_TOKEN`
   (`Settings → Secrets and variables → Actions → New repository secret`). The `osc token` output also includes a numeric `id`; the
   `runservice` endpoint uses the secret string in the
   `Authorization` header, not the id.

1. **Sanity-check the project once** before wiring CI: stand it up in
   `home:<user>:test-<tool>`, run one full cycle (manual tag push →
   `curl` → green Tumbleweed build), then rename to the real project.
   Renaming a published project breaks every `zypper addrepo` URL
   your users may have saved.

#### 5.3.2 Files to commit to the OBS package

Mirror them in `packaging/obs/` in your repo for version-control, then
`cd` into an `osc checkout` of the package and `osc add` / `osc commit`
from there.

**`_service`** — `obs_scm` in `mode="manual"` so it only runs when the
trigger fires (not on every commit, not on a server-side schedule):

```xml
<services>
  <service name="obs_scm" mode="manual">
    <param name="url">https://github.com/<user>/<tool>.git</param>
    <param name="scm">git</param>
    <param name="revision">main</param>
    <param name="versionformat">@PARENT_TAG@</param>
    <param name="versionrewrite-pattern">v(.*)</param>
    <param name="match-tag">v*</param>
    <param name="filename"><tool></param>
  </service>
  <service name="tar"          mode="buildtime"/>
  <service name="recompress"   mode="buildtime">
    <param name="file">*.tar</param>
    <param name="compression">gz</param>
  </service>
  <service name="set_version"  mode="buildtime"/>
</services>
```

`versionformat: @PARENT_TAG@` + `versionrewrite-pattern: v(.*)` derives
the package version from your latest `v*` tag (e.g. `v1.2.3` → `1.2.3`).
`set_version` rewrites the `Version:` line in both the `.spec` and the
`.dsc` at build time.

**`<tool>.spec`** — `BuildArch: noarch`; `%make_install` already
respects your GNU-conventions Makefile:

```spec
Name:           <tool>
Version:        0.0.0
Release:        0
Summary:        Short one-line description
License:        MIT
URL:            https://github.com/<user>/<tool>
Source0:        %{name}-%{version}.tar.gz
BuildArch:      noarch

BuildRequires:  make
BuildRequires:  bash

Requires:       bash >= 4.0
Requires:       coreutils
# Add only what your script actually invokes at runtime:
# Requires:     grep
# Requires:     sed
# Requires:     gawk

%description
Longer description.

%prep
%autosetup -n %{name}-%{version}

%build
%make_build

%install
%make_install PREFIX=%{_prefix} DESTDIR=%{buildroot}

%files
%license LICENSE
%doc README.md
%{_bindir}/%{name}
%{_datadir}/%{name}/

%changelog
# Maintained in git; obs-service-set_version fills the Version field
```

**Debian source set** — OBS's
[`debtransform`](https://en.opensuse.org/openSUSE:Build_Service_Debian_builds)
assembles a proper Debian source package from these flat files (no
`debian/` directory required):

- `<tool>.dsc` — control header with
  `DEBTRANSFORM-TAR: <tool>-%{version}.tar.gz` so the upstream
  tarball isn't ambiguous, and `DEBTRANSFORM-RELEASE: 1` to
  auto-bump the Debian release per build.
- `debian.control` — `Source:` block + `Package:` block, `Architecture: all` (noarch equivalent), `Depends: bash (>= 4.0), coreutils, ${misc:Depends}`.
- `debian.rules` — three-line `dh $@` form with an
  `override_dh_auto_install` that calls `$(MAKE) install DESTDIR=debian/<tool> PREFIX=/usr`.
- `debian.changelog` — minimal initial entry; `set_version` keeps it
  in sync at build time.

For a pure-Bash tool these four files are easier to hand-author than
to translate from the `.spec` via tooling. Skip `spec2deb`.

#### 5.3.3 CI trigger from GitHub Actions

Already wired in §4 — repeated here for reference:

```yaml
- name: Trigger OBS service run
  env:
    OBS_TOKEN: ${{ secrets.OBS_TOKEN }}
  run: |
    curl --fail-with-body -X POST \
      -H "Authorization: Token ${OBS_TOKEN}" \
      "https://api.opensuse.org/trigger/runservice?project=home:<user>:<tool>&package=<tool>"
```

OBS re-runs `_service`, fetches the new tag, and rebuilds for every
enabled repo. Latency from trigger to published binaries is typically
minutes-to-an-hour depending on the OBS build queue.

The alternative
[SCM/CI Workflow Integration](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-scm-ci-workflow-integration)
(`.obs/workflows.yml` + GitHub webhook + workflow token) is designed
for **PR-driven** branched test builds. For tag-driven release
rebuilds the one-line `curl` is simpler — pick SCM/CI only if you also
want per-PR test builds on OBS.

#### 5.3.4 End-user install

The README "Install" section gains a per-distro snippet. Get the
exact, current paths from
`https://software.opensuse.org/package/<tool>` (it auto-generates a
landing page per package from any public OBS project):

```bash
# openSUSE Tumbleweed
zypper ar https://download.opensuse.org/repositories/home:<user>:<tool>/openSUSE_Tumbleweed/home:<user>:<tool>.repo
zypper in <tool>

# Fedora
dnf config-manager --add-repo https://download.opensuse.org/repositories/home:<user>:<tool>/Fedora_41/home:<user>:<tool>.repo
dnf install <tool>

# Debian / Ubuntu — repo-add snippet on software.opensuse.org
```

openSUSE users also get a free
[1-Click Install](https://en.opensuse.org/openSUSE:One_Click_Install)
`.ymp` button on the software.opensuse.org page — no extra action
required from the maintainer.

Build status badge for the README:

```markdown
![OBS build](https://build.opensuse.org/projects/home:<user>:<tool>/packages/<tool>/badge.svg?type=default)
```

### 5.4 What to skip (for now)

- **Homebrew tap** — Mac-centric, low ROI for a Linux-only tool.
- **Nix flake / nixpkgs** — only if a user requests it.
- **bpkg / basher / eget** — low adoption among end users.
- **Self-hosted apt/yum repo on your own infra** (Cloudsmith,
  packagecloud, GitHub Pages + `apt-ftparchive`) — OBS already gives
  you signed, hosted repos for free; only self-host if you have
  air-gapped/enterprise users who can't reach `download.opensuse.org`.
- **[nfpm](https://github.com/goreleaser/nfpm) for `.rpm`/`.deb`** —
  was the lean choice before OBS, but it only emits files (you'd
  still need to host a repo). OBS does both. Keep nfpm in mind only
  if you want `.rpm`/`.deb` *attached to the GitHub Release itself*
  with zero external service — see Alternatives below.

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
publishes the release with generated notes, and triggers an OBS service
run that rebuilds the `.rpm`/`.deb` for every enabled distro. The
`install.sh` one-liner picks up the new tag immediately; the AUR
package picks it up after a `git subtree push --prefix packaging/aur/<tool> aur:<tool> master`; OBS-hosted repos refresh within minutes-to-an-hour
once the build queue drains.

## Files to add — checklist

| Path                                  | Purpose                                                                                                                                                       |
| ------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `VERSION`                             | One line, e.g. `0.1.0`. Source of truth.                                                                                                                      |
| `cliff.toml`                          | git-cliff config (Keep-a-Changelog preset).                                                                                                                   |
| `CHANGELOG.md`                        | Generated by git-cliff at each release; committed.                                                                                                            |
| `install.sh`                          | curl-piped installer: discover latest tag → download tarball + `.sha256` → verify → install to `~/.local` by default.                                         |
| `.github/workflows/release.yml`       | Tag-triggered: test → `make dist` → git-cliff notes → attest-build-provenance → `gh release create` → trigger OBS service run. Needs `OBS_TOKEN` repo secret. |
| `packaging/aur/<tool>/PKGBUILD`       | Stable-release PKGBUILD.                                                                                                                                      |
| `packaging/aur/<tool>-git/PKGBUILD`   | VCS variant tracking `main`.                                                                                                                                  |
| `packaging/obs/_meta.xml`             | OBS project `_meta` (repos enabled: Tumbleweed, Leap 15.6, Fedora_41, Debian_12, xUbuntu_24.04). Source of truth for `osc meta prj -e`.                       |
| `packaging/obs/_service`              | `obs_scm` (`mode="manual"`) pulling `main` and deriving version from `@PARENT_TAG@`; `tar` + `recompress` + `set_version` at build time.                      |
| `packaging/obs/<tool>.spec`           | RPM recipe — `BuildArch: noarch`, `%make_install PREFIX=%{_prefix} DESTDIR=%{buildroot}`.                                                                     |
| `packaging/obs/<tool>.dsc`            | Debian source control header with `DEBTRANSFORM-TAR` + `DEBTRANSFORM-RELEASE`.                                                                                |
| `packaging/obs/debian.control`        | Debian `Source:` + `Package:` blocks, `Architecture: all`.                                                                                                    |
| `packaging/obs/debian.rules`          | `dh $@` form with `override_dh_auto_install` calling `$(MAKE) install DESTDIR=debian/<tool> PREFIX=/usr`.                                                     |
| `packaging/obs/debian.changelog`      | Minimal initial entry; `set_version` keeps it in sync.                                                                                                        |
| Makefile edits                        | Add `PREFIX`/`DESTDIR`/`bindir`/`libdir`/`datadir`; add `dist:`; rewrite `install:`/`uninstall:` to use `$(DESTDIR)$(bindir)` etc.                            |
| Dispatcher script edit                | Implement `version` subcommand via `VERSION` file or `__TOOL_VERSION__` placeholder; fall back to `git describe` in dev.                                      |
| `README.md` / `docs/INSTALL.md` edits | New "Install" section: curl one-liner → AUR → OBS-hosted `zypper`/`dnf`/`apt` repos → from source. Plus OBS build-status badge.                               |

## Alternatives — when to pick them

- **[release-please](https://github.com/googleapis/release-please)
  instead of git-cliff + manual tag** — pick when you want every
  release proposed as a PR you merge to ship. Heavier, GitHub-locked,
  Node-based. Fine for SaaS, overkill for a single-maintainer Bash CLI.
- **GoReleaser-style monolithic config** — only worth it once shipping
  deb + rpm + apk + arch + homebrew + docker simultaneously. For a
  Bash project, hand-written workflow + OBS stays leaner.
- **[nfpm](https://github.com/goreleaser/nfpm) instead of OBS** —
  pick when you want `.rpm`/`.deb` attached to the GitHub Release
  itself with no external service. Single static Go binary, single
  YAML, runs in the same Actions job (seconds instead of OBS's
  minutes-to-hours). Trade-off: you don't get a hosted, signed,
  distro-native repo — users have to `dnf install ./foo.rpm` /
  `dpkg -i foo.deb` each version manually. Combine the two if you
  want both: nfpm for "drop-in download" + OBS for "add the repo
  once, auto-update forever."
- **[Fedora COPR](https://copr.fedorainfracloud.org/) instead of
  OBS** — Fedora-only, simpler than OBS, but no openSUSE/Debian/Ubuntu.
  Pick over OBS only if your users are Fedora-exclusive.
- **Self-hosted apt/yum repo on your own infra** — only when
  enterprise users refuse `curl | bash` *and* refuse OBS-hosted repos
  (rare — usually air-gapped environments).
- **OBS Arch-binary repo *instead of* AUR** — don't. OBS can produce
  a pacman repo at `download.opensuse.org/.../Arch/`, but Arch users
  expect to find packages via `yay`/`paru` against the AUR. Add OBS
  Arch only as an *additive* channel for users who can't use AUR
  (corporate, immutable distros) — never as a substitute.

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
- [openSUSE Build Service — home](https://openbuildservice.org/) — [build portal](https://build.opensuse.org/), [software search](https://software.opensuse.org/)
- [OBS User Guide — Authorization & Tokens](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-authorization-token)
- [OBS User Guide — Using Source Services](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-source-services)
- [OBS User Guide — SCM/CI Workflow Integration](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-scm-ci-workflow-integration)
- [OBS User Guide — Supported Build Recipes and Package Formats](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-package-formats)
- [OBS User Guide PDF](https://openbuildservice.org/files/manuals/obs-user-guide.pdf)
- [openSUSE wiki — Build Service Tutorial](https://en.opensuse.org/openSUSE:Build_Service_Tutorial)
- [openSUSE wiki — Specfile guidelines](https://en.opensuse.org/openSUSE:Specfile_guidelines)
- [openSUSE wiki — Build Service Concept SourceService](https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService) (`_service` reference)
- [openSUSE wiki — Build Service Debian builds](https://en.opensuse.org/openSUSE:Build_Service_Debian_builds) (`debtransform`)
- [openSUSE wiki — Build Service supported build targets](https://en.opensuse.org/openSUSE:Build_Service_supported_build_targets) (repo names)
- [openSUSE wiki — OBS repositories](https://en.opensuse.org/OBS_repositories)
- [openSUSE wiki — One Click Install (.ymp)](https://en.opensuse.org/openSUSE:One_Click_Install)
- [openSUSE wiki — osc CLI](https://en.opensuse.org/openSUSE:OSC)
- [openSUSE/obs-service-tar_scm](https://github.com/openSUSE/obs-service-tar_scm) (`obs_scm` implementation)
- [AppImage docs — Using the Open Build Service](https://docs.appimage.org/packaging-guide/hosted-services/opensuse-build-service.html) (worked token example)
- [nfpm](https://github.com/goreleaser/nfpm)
- [fpm](https://fpm.readthedocs.io/en/latest/getting-started.html)
- [Fedora COPR](https://copr.fedorainfracloud.org/)
- [meson — Creating releases (VERSION file pattern)](https://mesonbuild.com/Creating-releases.html)
