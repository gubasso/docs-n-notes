# Coordinating an upstream GitHub repo with OBS packaging

How to maintain a package whose upstream source lives on GitHub (or any other forge) and whose
packaging lives in OBS, without letting the two drift. The core discipline is **patches in OBS are
temporary**: every patch you add must have a parallel upstream PR, and it gets dropped the moment
upstream cuts a release containing the fix.

## The two repositories

| Repository            | Purpose                                 | Contains                                 |
| --------------------- | --------------------------------------- | ---------------------------------------- |
| **GitHub** (upstream) | Clean, buildable source history         | Real code; permanent fixes               |
| **OBS** (packaging)   | Build RPMs for every target distro/arch | `.spec`, `.changes`, _temporary_ patches |

The key rule:

> Carry a patch in the `.spec` only for as long as the same change is **not yet** present upstream.
> The moment upstream is fixed, delete the patch file and the `Patch:` lines from the `.spec`.

## Making a patch from a tarball

When the upstream source ships as a tarball (not a branched OBS source), the simple-mechanic flow
is:

```bash
# 1. Extract so you can see the file to patch
tar xf <pkg>-1.0.tar.gz
cp <pkg>-1.0/path/to/file <pkg>-1.0/path/to/file.orig

# 2. Make your edit
vim <pkg>-1.0/path/to/file

# 3. Generate a unified diff from the project root
diff -u <pkg>-1.0/path/to/file.orig <pkg>-1.0/path/to/file \
  > 0001-short-description.patch
```

Alternatives: `git format-patch` against the upstream tag, or `quilt`. Either gives a richer header
(author, date, subject) that survives review better than a plain `diff -u`.

Add the patch to the OBS checkout:

```bash
osc add 0001-short-description.patch
```

Update the spec — add a `PatchN:` line below the existing `Source0:`:

```spec
Source0:       <pkg>-%{version}.tar.gz
Patch0:        0001-short-description.patch
```

If the spec uses `%autosetup` (most do), no separate `%patch` macro is needed — `%autosetup` applies
all declared patches automatically. Without `%autosetup`, add `%patch0 -p1` in `%prep`.

Local build to verify before committing:

```bash
osc build --local --clean
```

For `_link`-based satellite packages, the mechanic is different (see
[setup-home-project-from-upstream.md](setup-home-project-from-upstream.md) §3 — patches go through
`<apply name="…"/>` in `_link`, not `Patch0:` in the spec).

## End-to-end lifecycle

### 1. When you discover a build failure or bug

1. **Fix it locally** and create a patch file (via `diff -u`, `git format-patch`, or `quilt`).
2. **Submit the same fix upstream** as a PR. Include an explanatory commit message and a link to the
   OBS build log or bug ID.
3. **Add the same patch to OBS**:

   ```spec
   Patch0: 0001-short-description.patch
   ```

   Bump only `Release:` (not `Version:`) so all targets get the backport.
4. **Document it** in `*.changes` via `osc vc`.

### 2. While the patch is pending upstream

- Keep the `PatchN:` line in the `.spec`.
- Tag the patch header with `Upstream-Status: Submitted` (or `Pending`) so the next maintainer knows
  it can be reaped once merged. A short header at the top of the patch:

  ```text
  # Upstream-Status: Submitted (https://github.com/<org>/<repo>/pull/<n>)
  # Bug-Ref: <bug-tracker-url>
  ```

- Build-test for every target you care about (Factory, Tumbleweed, Leap, your SLE lanes, x86_64,
  aarch64 if relevant).

### 3. After the PR is merged and a new upstream tag is cut

1. Refresh the tarball in OBS (via `tar_scm`, `obs_scm`, or `osc service run download_files`).
2. **Delete** the `PatchN:` line **and** the `.patch` file from OBS:

   ```bash
   osc rm 0001-short-description.patch
   ```

3. Bump `Version:` to the new upstream tag; reset `Release:` to `0` or `1`.
4. Add a `.changes` entry: _"Drop 0001-short-description.patch — fixed upstream in vX.Y.Z"_.
5. Commit, verify builds, submit to the downstream target (e.g. `osc sr`).

> If upstream merged the change but hasn't tagged a release yet, you can either regenerate the
> tarball from a commit hash or keep the patch a little longer. Both are acceptable if documented.

## Keeping both repos in sync

- **In GitHub**: the `.spec` (if it lives there too) should **never** list a patch already applied
  in the source tree — that double-applies.
- **In OBS**: temporary patches are fine but must carry complete metadata (why, bug/PR URL, upstream
  status). A bare `Patch0: fix-thing.patch` with no header rots silently.
- A common technique is a branch in upstream Git (e.g. `packaging/openSUSE`) containing only
  spec-file tweaks, while `main` tracks the upstream code unchanged.

## Tips

- Use `quilt pop -a; quilt push -a` before every OBS build to verify the patch stack applies cleanly
  against the current tarball.
- Annotate patches fully — openSUSE guidelines prefer a header including synopsis, rationale, and
  `Upstream-Status`.
- Confirm a bug is truly fixed before dropping a patch (avoid silent regressions).
- Backport only what's necessary — smaller diffs mean fewer merge headaches.
- Keep `%if 0%{?sle_version}` / `%if 0%{?is_opensuse}` conditionals minimal — OBS feeds the right
  macros per target.
- Bump `Release:` for patch-only rebuilds; reset to `1` when `Version:` changes.

## See also

- [setup-home-project-from-upstream.md](setup-home-project-from-upstream.md) — `_link` + `<apply>`
  overlays for satellite packages (the patch mechanic for branched sources rather than tarball-based
  sources).
- [osc-commands.md](osc-commands.md) — the verbs (`osc add`, `osc rm`, `osc vc`, `osc commit`,
  `osc sr`) called out above.
- [openSUSE Patch Guidelines](https://en.opensuse.org/openSUSE%3APackaging_Patches_guidelines).
- [openSUSE Git Packaging Workflow](https://en.opensuse.org/openSUSE%3AGit_Packaging_Workflow).
