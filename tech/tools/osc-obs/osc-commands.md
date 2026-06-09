# `osc` command reference

> <https://en.opensuse.org/openSUSE:OSC> · <https://github.com/openSUSE/osc>

`osc` is the CLI for the Open Build Service. It works like a version-control system for packages:
checkout, edit, build locally, commit, submit-request.

This page is a compact cheat sheet of the verbs grouped by workflow. For end-to-end walkthroughs,
see [setup-home-project-from-upstream.md](setup-home-project-from-upstream.md) and the case studies
under [case-studies/](case-studies/).

## Authentication and setup

```bash
osc ls                    # sanity-check your login / list projects
```

For credential setup in a devcontainer (no host keyring), see
[auth-in-devcontainers.md](auth-in-devcontainers.md).

## Checkout and branch

`osc co`'s synopsis is `osc co PROJECT [PACKAGE] [FILE]` — two space-separated positionals, not a
slash-joined `PROJECT/PACKAGE` (verify with `osc help co`). `osc branch`'s synopsis is
`osc branch SOURCEPROJECT SOURCEPACKAGE [TARGETPROJECT | . [TARGETPACKAGE]]`.

```bash
# Check out a package (download a working copy)
osc co openSUSE:Factory <package>
osc co home:<your-user>:branches:<source-project> <package>

# Branch a package (like a fork — sets up build targets automatically)
osc branch <source-project> <package>
osc branch <source-project> <package> home:<your-user>:branches:<source-project> <package>

# Branch then checkout in one step
osc branch openSUSE:Factory <package> home:<your-user> <package>
osc co home:<your-user> <package>
```

The four-arg `osc branch` form lets you rename the target package on the fly — useful when the
source-package name differs from the binary you actually want to override. See
[libexpat-source-naming.md](libexpat-source-naming.md) for a worked example.

## Working with sources

```bash
osc up                    # update working copy (like git pull)
osc status                # what's changed locally
osc diff                  # show actual diffs
osc ar                    # add/remove — detect new and deleted files
osc add <file>            # add a specific file
osc addpatch fix-foo.patch  # add a patch file
```

`osc ar` is what you reach for after renaming, deleting, or adding files in the working copy — it
reconciles the local file set with what OBS expects. See
[broken-state-link-drift.md](broken-state-link-drift.md) for the failure mode this prevents.

## Changelog

```bash
osc vc                    # open changelog editor (auto-fills dates)
```

Or hand-edit the `*.changes` file / the `%changelog` section in the spec.

## Building

```bash
# Local build (in a chroot — no OBS server interaction)
osc build
osc build --local
osc build --local-package
osc build --local --clean

# Build for specific targets
osc build Factory x86_64
osc build 15.4 x86_64
osc build 15.5 aarch64
osc build openSUSE_Tumbleweed x86_64

# Linting
rpmlint <package>.spec
osc lint <package>.spec    # if osc-lint plugin is installed
```

Build logs and artifacts go to `~/rpmbuild/BUILDROOT/` or `~/.osc/`.

## Committing and submitting

```bash
# Commit to OBS (triggers remote build)
osc commit -m "<package>: <change summary>"

# Check remote build status
osc results
osc buildresults <project> <package>
osc buildlog                     # view build log for the current lane
```

For interpreting result states, see [blocked-state-is-transient.md](blocked-state-is-transient.md)
and [broken-state-link-drift.md](broken-state-link-drift.md).

```bash
# Submit request (like a PR — merge branch into target project)
osc sr -m "update to version 5.1.6"
osc submitreq
osc request submit
```

## Services

```bash
osc service mr                   # manual run of _service file
osc service run download_files   # refresh tarball from upstream
```

## Testing installation

```bash
# Add your OBS repo
zypper ar \
  https://download.opensuse.org/repositories/home:/<your-user>:/<package>/<distro>/ \
  <package>
zypper ref
zypper in <package>

# Verify installed RPM
rpm -ql <package> | grep <expected-file>
```

## Getting changes from the link target back into your branch

`osc` does not have a top-level `merge` verb. To pull upstream changes into a branched/linked
package, use `osc pull` from inside the working copy:

```bash
osc pull                          # merge the link target's changes into the working copy
```

To send your branch's changes the other way (back into the upstream project), open a submit request
with `osc sr` — see "Committing and submitting" above. Maintainers of the target project review and
merge it server-side.

## See also

- [setup-home-project-from-upstream.md](setup-home-project-from-upstream.md) — end-to-end
  home-project walkthrough.
- [common-mistakes-and-pitfalls.md](common-mistakes-and-pitfalls.md) — the CLI foot-guns and
  workspace mistakes worth memorizing before you hit them.
- [`~/DocsNNotes/tech/systems/linux/opensuse/opensuse-build-service-obs.md`](../../systems/linux/opensuse/opensuse-build-service-obs.md)
  — curated upstream-URL index (user guides, packaging guidelines, cheat sheets).
