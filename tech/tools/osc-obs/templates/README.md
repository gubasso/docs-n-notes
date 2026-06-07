# OBS metadata templates

Reusable XML templates for OBS project (`_meta`) and package (`_meta`) descriptors. Copy, fill in
the placeholders, and apply with `osc meta -F`.

## Files

- [`project-meta.xml`](project-meta.xml) — generic project metadata with common build targets
  (Tumbleweed, Leap, an SLE example).
- [`package-meta.xml`](package-meta.xml) — minimal package metadata (title, description, upstream
  URL).
- [`example-package-meta.xml`](example-package-meta.xml) — a realistic, applied package metadata
  file for reference (real public upstream, no placeholders).

## Usage

```bash
# 1. Copy a template
cp project-meta.xml my-project-meta.xml

# 2. Fill in placeholders (YOURUSER, PROJECTNAME, etc.)
vim my-project-meta.xml

# 3. Create the project on OBS
osc meta prj home:<your-user>:my-project -F my-project-meta.xml

# 4. Same for the package
cp package-meta.xml my-package-meta.xml
vim my-package-meta.xml
osc meta pkg home:<your-user>:my-project/my-package -F my-package-meta.xml
```

## Placeholders

| Placeholder   | Replace with         | Example               |
| ------------- | -------------------- | --------------------- |
| `YOURUSER`    | Your OBS username    | `<your-obs-username>` |
| `PROJECTNAME` | Project name         | `my-overlay-project`  |
| `PACKAGENAME` | Package name         | `my-package`          |
| `OWNER/REPO`  | Upstream GitHub path | `<gh-org>/<gh-repo>`  |

## Customizing build targets

Edit the `<repository>` blocks in `project-meta.xml`. Common targets:

```xml
<!-- openSUSE Tumbleweed (rolling) -->
<repository name="openSUSE_Tumbleweed">
  <path project="openSUSE:Tumbleweed" repository="standard"/>
  <arch>x86_64</arch>
</repository>

<!-- openSUSE Leap -->
<repository name="openSUSE_Leap_15.6">
  <path project="openSUSE:Leap:15.6" repository="standard"/>
  <arch>x86_64</arch>
</repository>

<!-- SLE service-pack overlay (see sle-update-pool-vs-standard.md for path ordering) -->
<repository name="SLE_15_SP6">
  <path project="SUSE:SLE-15-SP6:Update" repository="pool"/>
  <path project="SUSE:SLE-15-SP6:GA"     repository="standard"/>
  <arch>x86_64</arch>
</repository>
```

Path order matters — the resolver uses the first `<path>` as the base and falls through to later
paths for unsatisfied BuildRequires. See
[`../sle-update-pool-vs-standard.md`](../sle-update-pool-vs-standard.md) for the `Update:pool` vs
`:standard` distinction and the
[`../setup-home-project-from-upstream.md`](../setup-home-project-from-upstream.md) §1 rules of thumb
for choosing repos.

## Templates vs examples

- **`project-meta.xml` / `package-meta.xml`** — generic XML with placeholders (`YOURUSER`,
  `PROJECTNAME`, `OWNER/REPO`) as a starting point.
- **`example-package-meta.xml`** — a real, applied metadata file for a public upstream package.
  Useful as a worked reference; not meant to be copied verbatim.

## Adding a new example

To capture an applied metadata file from a working OBS project:

```bash
osc meta prj <project> > project-meta.xml
osc meta pkg <project>/<package> > package-meta.xml
```

Before committing, scrub any personal identifiers (your `home:<user>:` project name, real usernames)
and replace with placeholders.
