# Bash Release — OBS (openSUSE, Fedora, Debian, Ubuntu)

Part of the [bash release-workflow spec](README.md). General principle: **distribution channels** —
see the [general principles](../../../programming/release-workflow/README.md).

The [openSUSE Build Service](https://openbuildservice.org/) builds `.rpm` and `.deb` from a single
`.spec` + `debian.*` set and **hosts the signed repos** at
`https://download.opensuse.org/repositories/home:<user>:<tool>/<distro>/`. End users add the repo
once; `zypper` / `dnf` / `apt` handle updates from then on.

OBS pulls source from your `v*` tag via
[`obs_scm`](https://github.com/openSUSE/obs-service-tar_scm), so the GitHub tag stays the single
source of truth — CI never uploads tarballs to OBS. The CI step in the
[CI release chapter](03-ci-release-workflow.md) only posts a one-line `curl` that tells OBS "the tag
moved, re-run services" — OBS does the rest.

## One-time OBS setup

Do these **once** in the web UI at [build.opensuse.org](https://build.opensuse.org/) (or via
[`osc`](https://en.opensuse.org/openSUSE:OSC) — install `osc` locally first):

1. **Create the project.** `home:<user>` is auto-created on first login; create a sub-project
   `home:<user>:<tool>` to isolate this tool's repos and metadata.

1. **Enable target repositories** in `_meta`. From the WebUI use _Repositories → Add from a
   Distribution_; from the CLI use `osc meta prj -e home:<user>:<tool>` and paste the XML below.
   Always cross-check current repo names in the WebUI picker — Leap versions move and Fedora numbers
   bump.

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

   For a `noarch` package, one `x86_64` per repo is enough — OBS builds the noarch artifact once per
   repo and serves it for every architecture.

1. **Create the package container.**

   ```bash
   osc meta pkg -e home:<user>:<tool> <tool>
   ```

1. **Create a scoped trigger token** (a leaked token can then only re-run _this_ package's services,
   not your whole account):

   ```bash
   osc token --create --operation runservice home:<user>:<tool> <tool>
   ```

   Store the secret string as the GitHub Actions secret `OBS_TOKEN`
   (`Settings → Secrets and variables → Actions → New repository secret`). The `osc token` output
   also includes a numeric `id`; the `runservice` endpoint uses the secret string in the
   `Authorization` header, not the id.

1. **Sanity-check the project once** before wiring CI: stand it up in `home:<user>:test-<tool>`, run
   one full cycle (manual tag push → `curl` → green Tumbleweed build), then rename to the real
   project. Renaming a published project breaks every `zypper addrepo` URL your users may have
   saved.

## Files to commit to the OBS package

Mirror them in `packaging/obs/` in your repo for version-control, then `cd` into an `osc checkout`
of the package and `osc add` / `osc commit` from there.

**`_service`** — `obs_scm` in `mode="manual"` so it only runs when the trigger fires (not on every
commit, not on a server-side schedule):

```xml
<services>
  <service name="obs_scm" mode="manual">
    <param name="url">https://github.com/<user>/<tool>.git</param>
    <param name="scm">git</param>
    <param name="revision">master</param>
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

`versionformat: @PARENT_TAG@` + `versionrewrite-pattern: v(.*)` derives the package version from
your latest `v*` tag (e.g. `v1.2.3` → `1.2.3`). `set_version` rewrites the `Version:` line in both
the `.spec` and the `.dsc` at build time.

**`<tool>.spec`** — `BuildArch: noarch`; `%make_install` already respects your GNU-conventions
Makefile:

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
[`debtransform`](https://en.opensuse.org/openSUSE:Build_Service_Debian_builds) assembles a proper
Debian source package from these flat files (no `debian/` directory required):

- `<tool>.dsc` — control header with `DEBTRANSFORM-TAR: <tool>-%{version}.tar.gz` so the upstream
  tarball isn't ambiguous, and `DEBTRANSFORM-RELEASE: 1` to auto-bump the Debian release per build.
- `debian.control` — `Source:` block + `Package:` block, `Architecture: all` (noarch equivalent),
  `Depends: bash (>= 4.0), coreutils, ${misc:Depends}`.
- `debian.rules` — three-line `dh $@` form with an `override_dh_auto_install` that calls
  `$(MAKE) install DESTDIR=debian/<tool> PREFIX=/usr`.
- `debian.changelog` — minimal initial entry; `set_version` keeps it in sync at build time.

For a pure-Bash tool these four files are easier to hand-author than to translate from the `.spec`
via tooling. Skip `spec2deb`.

## CI trigger from GitHub Actions

Already wired in the [CI release chapter](03-ci-release-workflow.md) — repeated here for reference:

```yaml
- name: Trigger OBS service run
  env:
    OBS_TOKEN: ${{ secrets.OBS_TOKEN }}
  run: |
    curl --fail-with-body -X POST \
      -H "Authorization: Token ${OBS_TOKEN}" \
      "https://api.opensuse.org/trigger/runservice?project=home:<user>:<tool>&package=<tool>"
```

OBS re-runs `_service`, fetches the new tag, and rebuilds for every enabled repo. Latency from
trigger to published binaries is typically minutes-to-an-hour depending on the OBS build queue.

The alternative
[SCM/CI Workflow Integration](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-scm-ci-workflow-integration)
(`.obs/workflows.yml` + GitHub webhook + workflow token) is designed for **PR-driven** branched test
builds. For tag-driven release rebuilds the one-line `curl` is simpler — pick SCM/CI only if you
also want per-PR test builds on OBS.

## End-user install

The README "Install" section gains a per-distro snippet. Get the exact, current paths from
`https://software.opensuse.org/package/<tool>` (it auto-generates a landing page per package from
any public OBS project):

```bash
# openSUSE Tumbleweed
zypper ar https://download.opensuse.org/repositories/home:<user>:<tool>/openSUSE_Tumbleweed/home:<user>:<tool>.repo
zypper in <tool>

# Fedora
dnf config-manager --add-repo https://download.opensuse.org/repositories/home:<user>:<tool>/Fedora_41/home:<user>:<tool>.repo
dnf install <tool>

# Debian / Ubuntu — repo-add snippet on software.opensuse.org
```

openSUSE users also get a free [1-Click Install](https://en.opensuse.org/openSUSE:One_Click_Install)
`.ymp` button on the software.opensuse.org page — no extra action required from the maintainer.

Build status badge for the README:

```markdown
![OBS build](https://build.opensuse.org/projects/home:<user>:<tool>/packages/<tool>/badge.svg?type=default)
```

## What to skip (for now)

- **Homebrew tap** — Mac-centric, low ROI for a Linux-only tool.
- **Nix flake / nixpkgs** — only if a user requests it.
- **bpkg / basher / eget** — low adoption among end users.
- **Self-hosted apt/yum repo on your own infra** (Cloudsmith, packagecloud, GitHub Pages +
  `apt-ftparchive`) — OBS already gives you signed, hosted repos for free; only self-host if you
  have air-gapped/enterprise users who can't reach `download.opensuse.org`.
- **[nfpm](https://github.com/goreleaser/nfpm) for `.rpm`/`.deb`** — was the lean choice before OBS,
  but it only emits files (you'd still need to host a repo). OBS does both. Keep nfpm in mind only
  if you want `.rpm`/`.deb` _attached to the GitHub Release itself_ with zero external service — see
  the [release ritual & alternatives chapter](06-release-ritual-and-alternatives.md).
