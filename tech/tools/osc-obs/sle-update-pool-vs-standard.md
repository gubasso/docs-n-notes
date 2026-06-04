# `SUSE:SLE-15-SPx:Update` binaries live in `pool`, not `standard`

> Topic: when you need to expose a SUSE maintenance lane's binaries to a downstream consumer (a home
> project, a side-build, a CI repo), the resolver `<path>` you add to your project's `_meta` must
> point at the `pool` repository, **not** `standard`. The `standard` repo on a
> `kind="maintenance_release"` project is empty; `pool` aggregates the binaries published by
> maintenance incidents. The same shape applies to other distros' maintenance-release projects on
> different OBS instances — only the project naming changes.

## TL;DR

- `SUSE:SLE-15-SP<n>:Update` (and other `kind="maintenance_release"` projects) typically have
  project-level `<build><disable/></build>` and `<publish><disable/></publish>`. Nothing publishes
  via the project's top-level `standard` repo.
- The actual published maintenance binaries land in the **`pool`** repository — that's the catch-all
  where incident-built RPMs live.
- The canonical consumer-side resolver path is therefore:

  ```xml
  <path project="<source-distro>:<version>:Update" repository="pool"/>
  ```

  Place it above the matching `<source-distro>:<version>:GA` path so the maintenance version wins
  when present.
- The narrower sub-repos (`SLE-Module-Python3`, `SLE-Module-Basesystem`, …) listed under `:Update`'s
  `_meta` cover _some_ binaries but not every maintenance incident. `pool` is the only sub-repo
  guaranteed to surface a given maintenance binary if it has ever published.

## How to recognize the trap

The two probes that disambiguate `:Update`'s publish topology:

```bash
# Probe 1 — top-level standard (almost certainly empty for :Update)
osc -A <api> api \
  '/build/<source-project>/standard/<arch>/_repository'
# → <binarylist/>     ← red flag

# Probe 2 — pool (where the binaries actually live)
osc -A <api> api \
  '/build/<source-project>/pool/<arch>/_repository?view=binaryversions&binary=<binary>&withevr=1'
# → <binary name="…" evr="…" arch="…"/>
```

Confirm the project's `kind` and project-level publish state if you need to rule out other causes:

```bash
osc -A <api> meta prj <source-project> \
  | grep -E '(kind=|<(build|publish)>)'
```

A `kind="maintenance_release"` line + `<build><disable/></build>` + `<publish><disable/></publish>`
is the unambiguous signature.

## Canonical resolver `<path>`

In the consumer project's `_meta`, for the lane that should see the maintenance updates:

```xml
<repository name="<lane-name>">
  <path project="<source-distro>:<version>:Update" repository="pool"/>     <!-- new -->
  <path project="<source-distro>:<version>:GA" repository="standard"/>
  <arch>x86_64</arch>
</repository>
```

Why `pool` above `:GA/standard` — the resolver tries `<path>` entries in order; a
maintenance-updated binary in `pool` should preempt the GA-shipped one.

## When to prefer `<path>` over `osc branch`

This pattern is the **passive** counterpart to `osc branch`-style branched providers (see
[`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md) §4). Both expose
upstream binaries to your home project; the trade-off is:

| Approach               | Upstream tracking                                                | Maintenance cost                                                    | Best for                                                                         |
| ---------------------- | ---------------------------------------------------------------- | ------------------------------------------------------------------- | -------------------------------------------------------------------------------- |
| `<path>` in `_meta`    | Auto — every new EVR upstream publishes is visible on next build | One-line `_meta` edit, zero source packages owned locally           | Distro-shipped binaries from a maintenance pool; no local patches needed         |
| `osc branch` (`_link`) | Manual — requires `osc up` to refresh after upstream bumps       | One source package owned per branch, `_link` plus any local patches | When you actually need to patch the source, or the binary doesn't exist upstream |

If the binary exists upstream and you only need it as-is in your buildroot, `<path>` is strictly
less work than `osc branch`.

## Worked example — typical missing-provider story

A consumer project's `<lane>` lane is `unresolvable` on N binaries that the GA distro path doesn't
ship. The naive instinct is to `osc branch` each provider from a newer SP or from Factory. Before
doing that:

1. Probe `<source-project>/pool/<arch>/_repository` with
   `view=binaryversions&binary=<missing>&withevr=1` for each missing binary. If they all return
   `evr=…`, the maintenance lane already has them.
2. If yes, prefer the one-line `_meta` `<path>` edit over N `osc branch` invocations. Strictly less
   topology change in your project, strictly more passive tracking, no per-binary source-package
   maintenance burden.
3. If the probe returns `error="not available"` for some binaries but `evr=…` for others, you have a
   mixed picture: add the `<path>` for the bulk and fall back to `osc branch` only for the
   stragglers.

The same `pool` aggregation explains cross-SP curiosities in `_buildenv` files when a consumer
builds on a different SP than the binary it picks up — the resolver follows whatever `<path>` chain
the consumer's `_meta` declares, and a maintenance `pool` on one SP may surface a binary that
doesn't exist on another SP at all.

For an applied-version example with concrete project / package names, see the in-repo
`docs/osc-obs/` companion of the project that uses this skill.

## Sources

- [OBS User Guide — Maintenance setup](https://openbuildservice.org/help/manuals/obs-user-guide/cha.obs.maintenance_setup.html)
  — describes `kind="maintenance_release"` projects and their publish model.
- The empty-`standard` signature is reproducible against any `SUSE:SLE-15-SP<n>:Update` on
  `api.opensuse.org` — the same shape applies to other distros' maintenance-release projects on
  different OBS instances; only the project name changes.

## Cross-references

- [`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md) §4 — "Branched
  providers" pattern. The note at the top of §4 references this file for the passive alternative.
- [`case-studies/02-libexpat-abi-override-via-sles-update-branch.md`](case-studies/02-libexpat-abi-override-via-sles-update-branch.md)
  — that case branched the provider into the home project because the binary needed a local rebuild
  (cross-SP ABI). Compare and contrast with this file's pattern: branch when you need to _modify_
  the binary; add a `<path>` when you only need to _expose_ the upstream binary as-is.
- [`common-mistakes-and-pitfalls.md`](common-mistakes-and-pitfalls.md) — the project-shape and
  resolver-topology category. When in doubt between `osc branch` and `<path>`, default to the
  cheaper option (this file's pattern) and only escalate to branching when you actually need to
  change the source.
