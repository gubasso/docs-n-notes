# Bash Release — Versioning & Source of Truth

Part of the [bash release-workflow spec](README.md). General principle: **versioning & source of
truth** — see the [general principles](../../../programming/release-workflow/README.md).

A lean, opinionated workflow for releasing and distributing a Bash CLI on Linux. Targets a
single-maintainer pure-Bash project (no compiled artifacts, "noarch" payload). One source of truth
(a signed `v*` git tag) fans out to: a `curl | bash` installer, an AUR package, and the openSUSE
Build Service (OBS) for `.rpm`/`.deb` across openSUSE, Fedora, Debian, and Ubuntu.

> **Bash diverges from the general registry-publish model.** There is no central package registry
> (no crates.io / npm / PyPI equivalent that _is_ the release). A Bash program's "release" is a git
> tag plus a GitHub/GitLab Release plus distribution channels (`install.sh`, AUR, OBS, distro
> packages). **Tagging is publishing.** Everything downstream keys off the signed `v*` tag.

## When this applies

- Pure Bash (or mostly Bash) CLI tool, no compiled artifacts.
- Distributed to Linux hosts.
- Currently installed via `git clone && make install`, and you want something leaner/safer for end
  users.
- Single maintainer or small team — no need for GoReleaser-class monoliths.

## The lean default path

**Tag → tarball → GitHub Release → `install.sh` + AUR + OBS.**

Six moving parts:

1. `VERSION` file as single source of truth.
1. Conventional commits + `git-cliff` for `CHANGELOG.md`.
1. `Makefile` that respects `PREFIX`/`DESTDIR` (GNU conventions) and has a `dist` target.
1. GitHub Actions workflow triggered on `v*` tag → builds tarball, attaches `SHA256SUMS` + SLSA
   provenance, publishes release, triggers the OBS service run.
1. AUR PKGBUILDs (stable + `-git`) pushed via `git subtree` from `packaging/aur/`.
1. OBS project (`home:<user>:<tool>`) pulls the same `v*` tag via `obs_scm` and emits signed
   `.rpm`/`.deb` repos for openSUSE Tumbleweed/Leap, Fedora, Debian, Ubuntu. End-user install: curl
   one-liner, AUR (`yay`/`paru`), or `zypper ar` / `dnf config-manager` / `apt` against the
   OBS-hosted repo.

The maintainer's working branches are `develop` (integration) and `master` (release); the release
tag is cut on `master`.

## Versioning — single source of truth

Add a `VERSION` file at the repo root containing one line:

```text
0.1.0
```

This is what GNU coding standards and packaging tools (OBS `set_version`, `nfpm`, RPM `%autosetup`)
expect.

Two equivalent ways to expose it from the binary's `version` subcommand:

- **Ship `VERSION` alongside the lib** — `make install` copies it into `$(datadir)/<tool>/VERSION`;
  the dispatcher cats it. Zero build step.
- **Placeholder substitution at install time** — script contains `TOOL_VERSION="__TOOL_VERSION__"`,
  and `make install` runs `sed -i "s/__TOOL_VERSION__/$$(cat VERSION)/"` on the installed copy.
  Cleaner for tarball and git users alike.

For developer builds (running from a git checkout), fall back to
`git describe --tags --dirty --always` so `version` is always informative.

Follow [SemVer](https://semver.org/) for the numbering.
