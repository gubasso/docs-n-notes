# Setting up an OBS home project that overlays upstream packages

> <https://openbuildservice.org/help/manuals/obs-user-guide/> <https://en.opensuse.org/openSUSE:OSC>
> <https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService>

A from-scratch, project-agnostic walkthrough for an OBS home project that:

- pulls one **base package** from upstream (either directly imported from a local git checkout or
  branched from a distro project),
- and overlays one or more **satellite packages** (link to upstream
  - apply a local patch) so they build the same way as the base package on each target service pack.

This is the pattern that keeps a test repo coherent across multiple distro lanes (SLES 15 SP4–SP7
and 12 SP5 in the worked example — SP4 and 12 SP5 are LTSS-only as of 2026, still actively
maintained; the shape is the same for any distro family).

For the related auth setup and the recovery flow when an overlay goes wrong, see the
[README index](./README.md) in this subtree.

## 0. Prerequisites

- `osc` is installed (`zypper in osc` on SUSE; available in most distro repos elsewhere) — see
  [auth-in-devcontainers.md](./auth-in-devcontainers.md) if you're running inside a devcontainer.
- You have an OBS account on the instance you're targeting (`https://api.opensuse.org` for the
  public instance; SUSE IBS has its own URL). `osc -A <api> api /person/<user>` returns a `<person>`
  XML body — that's the canonical scripted auth probe.
- `obs-build` is installed if you want `osc vc` to update `.changes` files (it shells out to
  `/usr/lib/build/vc`). Without it, `osc ci` still works; only the changelog entry is skipped.
- A local workspace directory (e.g. `~/Projects/_obs-work/`) where package checkouts will live, kept
  independent of any source-code git tree.

## 1. Create the project

`osc meta prj -e <project>` opens `$EDITOR` with the project's `_meta` XML. For a fresh home
project:

```xml
<project name="home:<user>:<project>">
  <title>One-line description</title>
  <description>Optional longer description.</description>
  <person userid="<user>" role="bugowner"/>
  <person userid="<user>" role="maintainer"/>
  <build>    <enable/></build>
  <publish>  <enable/></publish>
  <debuginfo><enable/></debuginfo>

  <repository name="SLE_15_SP7">
    <path project="SUSE:SLE-15-SP7:Update" repository="standard"/>
    <path project="SUSE:SLE-15-SP7:GA"     repository="standard"/>
    <arch>x86_64</arch>
  </repository>
  <repository name="SLE_15_SP6">
    <path project="SUSE:SLE-15-SP6:GA" repository="standard"/>
    <arch>x86_64</arch>
  </repository>
  <!-- repeat per SP you care about -->
</project>
```

Rules of thumb:

- **One `<repository>` per target SP**, with the lane name (e.g. `SLE_15_SP6`) matching whatever
  taxonomy your consumer uses to pick a repo at install time.
- The first `<path>` is the _base_ of the resolver search; the resolver looks at later `<path>`
  entries to satisfy any BuildRequires that don't resolve in the first. For SP7, listing `:Update`
  before `:GA` gives security-patched binaries first shot. For other SPs, `:GA` alone is usually
  enough.
- Add `<arch>aarch64</arch>` only when you need an arm64 lane — builds are not free, and extra
  arches surface unrelated failures.
- Trim aggressively: every lane you list takes scheduler time.

Save and exit; `osc` validates and pushes. `osc meta prj <project>` confirms.

## 2. Base package — import directly OR branch from upstream

There are two patterns here, and the right one depends on what you intend the home project to be:

### 2.a Direct import (when you build the base from your own source)

If the base package is something _you_ maintain and you want OBS to build the latest commit from
your dev branch, drive it from a CI-like script that:

1. Checks out the upstream git tree.
2. Generates a tarball matching the spec's `Source:` line.
3. `osc co <home-project> <pkg>` (creates the local workspace dir).
4. Drops the new tarball + the `.spec` + `.changes` into the dir.
5. `osc addremove && osc ci -m "…"` to commit.

No `_link` involved. The home project's package is a standalone source tree, not a link. The
repository `<path>`s from §1 still provide BuildRequires.

### 2.b Branch from a distro project (when you patch a stable release)

If the base is a distro-shipped package you want to apply local patches to without losing upstream
version bumps:

```bash
osc -A <api> branch <upstream-project> <pkg> <home-project>
osc -A <api> co <home-project> <pkg>
```

That creates a `_link` to the upstream package's current `srcmd5`. Local changes commit as a delta
on top.

Pick (a) when the home project's job is _integration testing_ of a package you own; pick (b) when
its job is _trying out a patch_ on a package you don't.

## 3. Satellite packages — `_link` + `<apply name="…patch"/>`

A satellite is any package that needs to be present in the home project for the base to install /
run, but whose source you want to keep in sync with upstream. Branch it once, then carry your delta
as a single auditable patch file.

```bash
osc -A <api> linkpac <upstream-project> <satellite-pkg> <home-project>
osc -A <api> co --unexpand-link <home-project> <satellite-pkg>
cd <home-project>/<satellite-pkg>
```

`_link` should look like:

```xml
<link project="<upstream-project>" package="<satellite-pkg>">
  <patches>
    <apply name="my-overlay.patch"/>
  </patches>
</link>
```

Drop `my-overlay.patch` into the dir (a standard unified diff against the upstream-expanded spec),
then:

```bash
osc add _link my-overlay.patch
osc ci -m "Add my-overlay.patch for <reason>"
```

OBS will expand the link, apply the patch, and build.

### Why `<apply>` and not `<topadd>`?

Older docs use `<topadd>` to prepend a few lines to the spec. Use `<apply>` instead:

- A `.patch` file is a single auditable diff. Code review sees one artifact, not "where does the
  inline string change land?".
- Patches can change `%build`, `%install`, `%files` — `<topadd>` is preamble-only.
- Patches survive upstream version bumps without manual rebasing as long as context lines match.
  `<topadd>` is fine forever, but you outgrow it the first time you need to fix a `%files` line.

## 4. Branched providers (when the distro doesn't ship a recent enough binary)

> **Before branching:** if the upstream project already publishes the binary you need under a shared
> aggregator repo (most commonly the `pool` repo on `kind="maintenance_release"` projects such as
> `SUSE:SLE-15-SP<n>:Update`), adding a `<path>` to your project's `_meta` is strictly less work
> than `osc branch` — no source package to own, no `_link` to keep in sync, and the resolver
> auto-tracks every new EVR upstream publishes. See
> [sle-update-pool-vs-standard.md](./sle-update-pool-vs-standard.md) for the probe recipe and the
> canonical `<path>` shape. Reach for the `osc branch` flow below only when you actually need to
> patch the source or the upstream project doesn't publish the binary you need.

Sometimes the resolver can't satisfy a BuildRequires because the distro's published binary is too
old. The fix is to branch the provider package into the home project, where its binary is rebuilt
and _prepended_ to the resolver search path for the home-project's lanes.

```bash
osc -A <api> branch openSUSE:Factory <provider-pkg> <home-project>
osc -A <api> results --watch <home-project> <provider-pkg>
```

Once the branched provider builds green, the home project publishes its binary at a higher version
than the distro path's, and the resolver picks the new one for any package whose `BuildRequires`
references it.

Watch out for ABI compatibility: the consuming package's BuildRequires must specify `>= <ver>` low
enough to match what Factory ships (or upstream-distro-Update, depending on which project you
branched from).

> Before you go further: every section below has a corresponding entry in
> [common-mistakes-and-pitfalls.md](./common-mistakes-and-pitfalls.md) for the failure mode each
> step prevents. If you hit something unexpected, that doc is the first place to look.

## 5. The orphan-patch trap

When you rename an overlay patch (e.g. bumping the patch name to reflect a wider gate or a different
distro target), you **must** in the same commit:

1. `osc add <new>.patch` — drop the new file in the source tree.
2. `osc rm <old>.patch` — drop the obsolete file _server-side_, even if it's gone from disk locally.
3. Update `_link`'s `<apply name="…"/>` to the new filename.
4. `osc ci -m "…"` — one commit, all four changes.

If you skip step 2, the source tree still contains the old patch but `_link.apply` points at the new
one — OBS's source service can't expand, every lane goes
`broken: patch '<new>'.patch does not exist`, and no build runs.

Any script that mechanically converges this state (a bootstrap script, a Python subcommand, etc.)
**must** enumerate the server-tracked files (`osc ls <project> <pkg>`), filter to `*.patch`, and
`osc rm` anything that isn't the current intended filename. See
[broken-state-link-drift.md](./broken-state-link-drift.md) for the full recovery flow when this has
already happened.

## 6. Verification sequence

After committing changes that should produce a green build:

```bash
# 6a. Watch all lanes settle. Ctrl-C is safe; the server keeps building.
osc -A <api> results --watch <home-project> <pkg>

# 6b. Confirm link expansion (catches link-drift before the resolver).
#     A working link returns 200 with the expanded spec body.
osc -A <api> api '/source/<home-project>/<pkg>?expand=1' | head

# 6c. Pull a built RPM for content verification.
#     -d <dir> is the destination directory; without -d, the 5th
#     positional is interpreted as a single FILE to download (a
#     classic foot-gun — passing 'binaries' silently downloads
#     nothing).
mkdir -p /tmp/verify && osc -A <api> getbinaries -d /tmp/verify \
  <home-project> <pkg> <repository> <arch>

# 6d. Inspect the payload.
rpm -qpl /tmp/verify/<pkg>-*.x86_64.rpm | grep site-packages
# Confirm the python ABI is what you expected (e.g. /usr/lib/python3.11/...).

# 6e. Inspect the build environment if you suspect resolver picked
#     the wrong provider for a BuildRequires.
grep 'bdep name="<provider>"' /tmp/verify/_buildenv
```

When something fails: the per-lane `osc -v results` message is usually the only diagnostic you need
to classify the failure (`broken: …`, `unresolvable: nothing provides …`, `failed`). For `broken`,
jump to [broken-state-link-drift.md](./broken-state-link-drift.md). For `unresolvable`, the
`osc buildinfo -d <project> <pkg> <repo> <arch>` call surfaces the resolver's full attempt and what
was missing. For `failed`, `osc buildlog … | tail -200` gives the compile error.

## 7. References

- OBS user guide: <https://openbuildservice.org/help/manuals/obs-user-guide/>
- `osc` reference: <https://en.opensuse.org/openSUSE:OSC>
- `osc(1)` man page: <https://manpages.opensuse.org/Tumbleweed/osc/osc.1.en.html>
- Spec file guidelines: <https://en.opensuse.org/openSUSE:Specfile_guidelines>
- Packaging conventions: <https://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros>
- Source service concept: <https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService>
- Companion files in this subtree:
  - [broken-state-link-drift.md](./broken-state-link-drift.md)
  - [auth-in-devcontainers.md](./auth-in-devcontainers.md)
  - [common-mistakes-and-pitfalls.md](./common-mistakes-and-pitfalls.md)
- Curated upstream-URL index:
  `~/DocsNNotes/tech/systems/linux/opensuse/opensuse-build-service-obs.md`
