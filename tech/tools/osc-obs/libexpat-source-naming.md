# libexpat in OBS — source pkg is `expat`, binary RPM is `libexpat1`

> <https://en.opensuse.org/openSUSE:Packaging_guidelines>
> <https://en.opensuse.org/openSUSE:Packaging_Conventions_RPM_Macros>
> <https://en.opensuse.org/openSUSE:OSC>

## tl;dr

Across `openSUSE:Factory`, `openSUSE:Leap:*`, `openSUSE:Backports:*`, and all `SUSE:SLE-*` projects,
the **source package** that builds the `libexpat1` binary RPM is named **`expat`**, not `libexpat`.
This is the standard openSUSE / SUSE packaging convention: source name follows the upstream project,
binary sub-packages follow the produced shared library. Confuse the two and `osc branch` / `osc co`
/ `osc meta pkg` return HTTP 404 for "package not found".

## Authoritative probe

```bash
osc -A <api> api \
  '/search/published/binary/id?match=@name="<binary-rpm>"+and+@project="<project>"'
```

Returns `<binary … package="<source-pkg>" version="…" …/>` — the `package=` attribute is the source
package name to use with `osc`. Example:

```bash
osc -A https://api.opensuse.org api \
  '/search/published/binary/id?match=@name="libexpat1"+and+@project="openSUSE:Factory"'
# → <binary name="libexpat1" project="openSUSE:Factory" package="expat" version="2.8.1" …/>
```

For projects the binary search doesn't expose (Leap, Backports),
`osc meta pkg <project>
<source-pkg-guess>` reveals where the source actually lives — the
`<package project="…">` attribute often points at the inheriting parent project (e.g.
`openSUSE:Leap:15.6/expat` reveals `SUSE:SLE-15-SP4:Update`).

## Branching with target-package rename

`osc branch` accepts an optional fourth positional that renames the package inside the target
project:

```bash
osc -A <api> branch \
  <src-prj> <src-pkg> \
  <tgt-prj> <tgt-pkg>
```

Concrete: branching SUSE's SP-Update `expat` and renaming the target to `libexpat` so a converger or
runbook that hard-codes the binary name keeps working:

```bash
osc -A https://api.opensuse.org branch \
  SUSE:SLE-15-SP<n>:Update expat \
  home:<user>:<project> libexpat
```

The new package's `_link` still points at `<linkinfo project="SUSE:…" package="expat" …/>`, so
upstream source flows naturally.

## Cross-project `libexpat1` / `expat` matrix

The relevant comparison axes for picking an `osc branch` source: tarball version (ABI), whether the
CVE-2025-59375 backport patch is present, and whether the source lane is the SLES-compatible choice
for the consumer that needs it.

| Source project                       | Tarball                        | CVE-2025-59375 backport           | Notes                                                                                                                                                                             |
| ------------------------------------ | ------------------------------ | --------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `openSUSE:Factory`                   | newest (≥ 2.8.x)               | upstream-fixed in 2.8.x           | Tumbleweed-bleeding-edge. Risks dragging newer-toolchain BR expectations into older SLE buildroots. Public; visible without SUSE creds.                                           |
| `SUSE:SLE-15-SP<n>:Update` (n=6,7,…) | 2.7.1 + patch                  | ✓ explicit `CVE-2025-59375.patch` | Each SP's Update channel — what production systems get via `zypper up`. **Most SLES-compatible** for overlay work scoped to that SP. Requires SUSE-employee/customer credentials. |
| `SUSE:SLE-15-SP<n>:GA`               | pre-CVE                        | ✗                                 | What ships with the SP at GA. Older `libexpat1` (~2.6.x), source of the CVE-2025-59375 ABI break. Never the right branch source for a backport workaround.                        |
| `SUSE:SLE-15:Update`                 | 2.7.1 + patch                  | ✓                                 | Common SLE15 Update channel (parent of SP-specific Updates). Viable if one branch should serve multiple SP lanes.                                                                 |
| `openSUSE:Leap:15.<n>`               | varies; 15.6 has 2.7.1 + patch | ✓ on 15.6                         | Leap inherits from a SLES base. Carries the patch when the underlying SLE Update channel does. Indirect — pick SP:Update over Leap when targeting a specific SP.                  |

The relevant ABI: the symbol `XML_SetAllocTrackerActivationThreshold` appears in `libexpat1` ≥
2.7.1. Consumers built against that ABI (`python311` from `SUSE:SLE-15-SP<n>:Update`) `ImportError`
on a pre-2.7.1 `libexpat1.so`.

## Converger-script pitfall

A `PROVIDERS=("libexpat|openSUSE:Factory")`-style list that uses the binary name as the source pkg
will either HTTP 404 on `osc branch` ("Package not found: `openSUSE:Factory/libexpat`") or, if the
agent later switches to the right source name but skips the target-rename, leave the home project
with a package called `expat` and silently break every downstream caller that hard-coded `libexpat`.

A function shape that survives both pitfalls:

```bash
ensure_branched() {
  local pkg="$1"
  local source_proj="$2"
  local source_pkg="${3:-$pkg}"   # default: tgt name == src name
  if "${OSC}" meta pkg "${HOME_PROJECT}" "${pkg}" >/dev/null 2>&1; then
    note "already branched into ${HOME_PROJECT}"
  else
    note "branching ${source_proj}/${source_pkg} → ${HOME_PROJECT}/${pkg}"
    "${OSC}" branch "${source_proj}" "${source_pkg}" "${HOME_PROJECT}" "${pkg}"
  fi
}

PROVIDERS=(
  "libexpat|SUSE:SLE-15-SP<n>:Update|expat"
)
```

The `|`-split fields are `target_pkg | source_proj | source_pkg`.

## Why Factory is rarely the right default for SLES overlay work

`openSUSE:Factory` is the public, no-auth path of least resistance for fetching libexpat — it
satisfies almost any `>= 2.7.x` BR with room to spare. But it ships Tumbleweed-newest packaging:
newer rpm macros, newer toolchain BRs, newer python ecosystem expectations. Branching Factory's
`expat` into a home project that overlays an older SLE base risks spurious `unresolvable` cascades
on adjacent packages whose BRs are too new for the SLE base.

When the agent runs as a SUSE-authenticated user, `SUSE:SLE-15-SP<n>:Update` is reachable. That's
the canonical source: it tracks exactly what `zypper up` on a production SP<n> system delivers, no
toolchain drift.

See also [`setup-home-project-from-upstream.md`](setup-home-project-from-upstream.md) for the
broader home-project overlay topology and
[`common-mistakes-and-pitfalls.md`](common-mistakes-and-pitfalls.md) for the binary-vs-source-name
foot-gun in the wider context of converger-script anti-patterns.
