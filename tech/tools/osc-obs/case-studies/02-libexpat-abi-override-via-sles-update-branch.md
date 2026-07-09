# Case study 02 — overriding a buildroot ABI by branching a SUSE Update package into the home project

> <https://en.opensuse.org/openSUSE:Build_Service_Tutorial> <https://en.opensuse.org/openSUSE:OSC>
> <https://en.opensuse.org/openSUSE:Packaging_guidelines>
> <https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-concepts>

## TL;DR

When a build fails because the buildroot resolves an upstream library at a version older than what a
same-buildroot consumer needs (classic example: `python311` from SP7:Update references
`XML_SetAllocTrackerActivationThreshold`, but the SP7:GA `libexpat1` is the pre-CVE 2.6.4 that lacks
that symbol), the recipe is: **branch the patched upstream package into the home project so the home
project's own published binary wins the resolver's path order, then verify with `_buildenv`.** Two
distinct foot-guns: (1) the **binary RPM name is not the source package name** — `libexpat1` ships
from source pkg `expat`. (2) **`openSUSE:Factory` is rarely the right branch source for SLES overlay
work** — it pulls Tumbleweed-newest packaging and risks toolchain drift in older SLE buildroots. The
SLES-compatible choice is `SUSE:SLE-15-SP<n>:Update/<src-pkg>`, which tracks exactly what production
systems get via `zypper up`. Use `osc branch <src-prj> <src-pkg>
<tgt-prj> <tgt-pkg>` with the 4-arg
form to rename the target package back to the binary name so downstream consumers and converger
scripts keep working.

## Goal

Bring `<satellite-pkg>` on `SLE_15_SP7` to `succeeded` with two simultaneous properties:

1. The installed payload lands under `/usr/lib/python3.11/site-packages/` (the python311 pin is
   active, not the system py3.6).
2. The SP7 buildroot shows `libexpat1 >= 2.7.1` **sourced from the home project**, not from
   `SUSE:SLE-15-SP7:GA`. That's the ABI override the satellite depends on for python311's pyexpat
   import to succeed at runtime.

If both hold, a downstream consumer's cross-ABI assertion stops firing on SP7 images.

## Challenge — what you'll trip over

This case study exercises three distinct OBS topics in sequence. Each one is its own foot-gun.

1. **Buildroot resolver path order.** OBS resolves BRs by walking the project's `<path>` entries in
   the order they're listed in `_meta`, **plus** the project's own published binaries (which take
   precedence within the same project). To override an upstream `libexpat1`, you can either reorder
   `<path>` entries or — more commonly — **publish your own `libexpat1` from a home-project
   package**, and the resolver will prefer it automatically. This case study uses the latter.

2. **Binary-name vs source-name convention.** Across `openSUSE:Factory`, `openSUSE:Leap:*`,
   `openSUSE:Backports:*`, and every `SUSE:SLE-*` project, the **source package** that builds the
   `libexpat1` binary RPM is named **`expat`**, not `libexpat`. Standard openSUSE / SUSE packaging
   convention: source name follows the upstream project, binary sub-packages follow the produced
   shared library. Get this wrong and `osc branch openSUSE:Factory libexpat …` returns HTTP 404
   ("Package not found: `openSUSE:Factory/libexpat`").

3. **Which source project is "right".** Several projects ship a viable `expat`:

   | Source project             | Tarball              | CVE-2025-59375 backport           | When to use                                                                                  |
   | -------------------------- | -------------------- | --------------------------------- | -------------------------------------------------------------------------------------------- |
   | `SUSE:SLE-15-SP<n>:Update` | 2.7.1 + patch        | ✓ explicit `CVE-2025-59375.patch` | **Default for SLES overlay work** — what `zypper up` on production SP<n> delivers.           |
   | `SUSE:SLE-15-SP<n>:GA`     | pre-CVE (~ 2.6.x)    | ✗                                 | Never. This is the version that _caused_ the ABI break.                                      |
   | `SUSE:SLE-15:Update`       | 2.7.1 + patch        | ✓                                 | If one branch should serve multiple SP lanes (parent of SP-specific Updates).                |
   | `openSUSE:Factory`         | ≥ 2.8.x              | upstream-fixed in 2.8.x           | Public, no-auth — but Tumbleweed-newest packaging risks toolchain drift in older buildroots. |
   | `openSUSE:Leap:15.<n>`     | varies; 15.6 = 2.7.1 | ✓ on 15.6                         | Indirect — prefer `SP<n>:Update` over Leap when you know the SP.                             |

   Picking `openSUSE:Factory` "because it's the public path of least resistance" is the wrong
   default when the consumer is an SLES buildroot. `SUSE:SLE-15-SP<n>:Update` is reachable for
   SUSE-employee / customer credentials and is the canonical, drift-free choice.

## What went wrong (timeline)

This played out across two `osc-obs` skill sessions. Both are preserved here as one timeline.

### Session 1 — the bootstrap script crashed because the source-pkg name was wrong

1. Initial state: `<satellite-pkg>` SP7 lane = `failed`,
   `ImportError: undefined symbol:
   XML_SetAllocTrackerActivationThreshold` at build time. Classic
   libexpat 2.6.4 vs python311 2.7.1-ABI mismatch.

2. The converger script (`<overlay-bootstrap>.sh`) had:

   ```bash
   BRANCHED_PROVIDERS=(
     "libexpat|openSUSE:Factory"
   )
   ```

   `ensure_branched` shelled out:

   ```bash
   osc branch openSUSE:Factory libexpat <home-project>
   # → Server returned an error: HTTP Error 404: Not Found
   # → Error getting meta for project 'openSUSE:Factory' package 'libexpat'
   # → Package not found: openSUSE:Factory/libexpat
   ```

3. **Two bugs in one line.** `openSUSE:Factory` doesn't have a package called `libexpat`; it has
   `expat` (which produces the `libexpat1` binary RPM). And even if the source name had been
   correct, `openSUSE:Factory` was a poor source choice for SLES overlay work.

4. **Authoritative discovery — the right source-pkg name.** The probe that resolves binary-RPM →
   source-pkg, against any project that publishes binaries:

   ```bash
   osc -A <api> api \
     '/search/published/binary/id?match=@name="libexpat1"+and+@project="openSUSE:Factory"'
   # → <binary name="libexpat1" project="openSUSE:Factory" package="expat" version="…" …/>
   ```

   The `package="…"` attribute is the source name. Lesson: **never guess the source name from the
   binary name — probe it.**

5. **Cross-project source survey.** With the right source name in hand, the survey across viable
   source projects (above table) made the decision easy: `SUSE:SLE-15-SP7:Update/expat` wins on
   three axes — most SLES-compatible, carries the CVE-2025-59375 backport explicitly, tracks exactly
   what production SP7 systems get via `zypper up`.

6. **User explicitly paused before executing the branch.** `osc branch` writes to shared state (the
   home project). The agent surfaced the decision matrix, the authoritative probes that supported
   it, and waited for explicit authorization. The next session resumed from the captured
   authorization rather than re-deriving it.

### Session 2 — execution and the Step 0 fast-path surprise

1. The authorized command (the 4-arg form, with target-rename):

   ```bash
   osc -A <api> branch \
     SUSE:SLE-15-SP7:Update expat \
     <home-project> libexpat
   ```

   Server response:
   `A working copy of the branched package can be checked out with: osc co
    <home-project>/libexpat`.
   Source listing showed `_link → SUSE:SLE-15-SP7:Update/expat`, `expat-2.7.1.tar.xz`,
   `CVE-2025-59375.patch`, and the in-tree CVE-2026 follow-ups already present.

2. `osc results --watch <home-project> libexpat` settled with SP7/SP6/SP5/SP4 all `succeeded`,
   SLE_12_SP5 `failed`. (12_SP5's libexpat lane out of scope — that lane's satellite doesn't enter
   the python311 BR arm. See Cross-cutting concerns below.)

3. **The satellite auto-rebuilt without any source-side commit.** Immediately after libexpat
   published on SP7, the OBS scheduler treated libexpat as an outdated dependency of the satellite
   and re-scheduled it. The satellite SP7 lane went from `failed` → `succeeded` on its own. The
   runbook had a planned Step 2 (un-comment the `BuildRequires: libexpat1 >= 2.7.1` line in the
   overlay patch) — that became unnecessary because the resolver naturally preferred the
   home-project libexpat over `SUSE:SLE-15-SP7:GA`. The runbook's Step 0 fast-path explicitly
   anticipated this case and jumped straight to payload verification.

4. **Verification — the three checks.** All three Step 5 stop criteria met:

   ```bash
   mkdir -p /tmp/verify/binaries && cd /tmp/verify && rm -rf binaries/*
   osc -A <api> getbinaries -d binaries <home-project> <satellite-pkg> SLE_15_SP7 x86_64

   rpm -qpl binaries/<satellite-pkg>-*.x86_64.rpm | grep site-packages
   # → /usr/lib/python3.11/site-packages/... (no python3.6 lines)

   grep 'bdep name="python311'  binaries/_buildenv
   # → python311-base 3.11.15 from SUSE:SLE-15-SP6:Update
   # → python311-setuptools 67.7.2 from SUSE:SLE-15-SP4:Update

   grep 'bdep name="libexpat1"' binaries/_buildenv
   # → <bdep name="libexpat1" version="2.7.1" release="150700.3.14.1" arch="x86_64"
   #    project="<home-project>" repository="SLE_15_SP7"/>
   ```

   `_buildenv` is the authoritative record of what the buildroot actually pulled in — much stronger
   evidence than just looking at the satellite's status code.

### Mistakes / foot-guns hit along the way

1. **Guessing the source-pkg name from the binary RPM name.** The bootstrap's
   `PROVIDERS=("libexpat|openSUSE:Factory")` line assumed source name == binary name. It almost
   never is. Probe with `/search/published/binary/id?match=@name="<binary>"` before encoding it
   anywhere.

2. **Defaulting to `openSUSE:Factory` for an SLES overlay.** Factory ships Tumbleweed-newest. For an
   SLES buildroot, prefer the SP-specific `:Update` channel — it's the same source the production
   system gets via `zypper up`, no toolchain drift.

3. **Assuming the satellite needs a source-side change to pick up the new libexpat.** It doesn't —
   the resolver naturally prefers home-project published binaries over upstream `<path>` entries
   within the same project. The auto-rebuild path "just works." (The trade-off is that without an
   explicit `BuildRequires: libexpat1 >= 2.7.1` in the satellite spec, a future regression where
   libexpat stops publishing would silently revert to the pre-CVE 2.6.4 buildroot and only surface
   at runtime. Adding the BR is hardening; not a build prerequisite.)

4. **Treating "satellite SP7 = succeeded" as the goal.** It isn't. The goal is "succeeded **AND**
   the buildroot pulled libexpat1 ≥ 2.7.1 from the home project." Always verify with `_buildenv`
   after a buildroot-shaping change; the status code alone proves nothing about which library was
   actually used.

5. **Forgetting to pre-flight every consumer lane's `binaryversions` before tightening a BR.** When
   you're about to commit `BuildRequires: libexpat1 >= 2.7.1`, probe every lane the BR will fire on
   to confirm that lane publishes a satisfying libexpat1. Otherwise you regress lanes that were
   green. The probe is one API call per lane:

   ```bash
   osc -A <api> api \
     '/build/<home-project>/<lane>/<arch>/_repository?view=binaryversions&binary=libexpat1&withevr=1'
   ```

## What I did to fix it

Two commands and one verification:

```bash
# 1. Branch the SP-specific Update channel's expat into the home project, renaming to libexpat
#    so any converger or runbook referring to it by the binary name still works.
osc -A <api> branch \
  SUSE:SLE-15-SP7:Update expat \
  <home-project> libexpat

# 2. Watch it publish on the lane you care about.
osc -A <api> results --watch <home-project> libexpat

# 3. After the satellite auto-rebuilds, verify the buildroot really used your libexpat.
mkdir -p /tmp/verify/binaries && cd /tmp/verify && rm -rf binaries/*
osc -A <api> getbinaries -d binaries <home-project> <satellite-pkg> <lane> <arch>
grep 'bdep name="libexpat1"' binaries/_buildenv   # must show project="<home-project>"
```

For the bootstrap script (out of scope this turn, but the right shape):

```bash
ensure_branched() {
  local pkg="$1"
  local source_proj="$2"
  local source_pkg="${3:-$pkg}"   # default: target name == source name
  if "${OSC}" meta pkg "${HOME_PROJECT}" "${pkg}" >/dev/null 2>&1; then
    note "already branched into ${HOME_PROJECT}"
  else
    note "branching ${source_proj}/${source_pkg} → ${HOME_PROJECT}/${pkg}"
    "${OSC}" branch "${source_proj}" "${source_pkg}" "${HOME_PROJECT}" "${pkg}"
  fi
}

PROVIDERS=(
  "libexpat|SUSE:SLE-15-SP<n>:Update|expat"     # target_pkg | source_proj | source_pkg
)
```

The `|`-split with an explicit source-pkg field accommodates the binary-vs-source naming asymmetry.
Use it whenever the binary name is more recognizable than the source name to downstream consumers
(very common for shared-library packages: `libfoo1` ships from `foo`).

## Correct path next time — the rule distilled

1. **Probe before encoding.** Never write a source-pkg name into a script, runbook, or commit
   message without first running:

   ```bash
   osc -A <api> api '/search/published/binary/id?match=@name="<binary-rpm>"+and+@project="<project>"'
   ```

   The `package="…"` attribute is authoritative. For projects the binary search doesn't expose
   (Leap, Backports), use `osc meta pkg <project> <source-pkg-guess>` and follow the
   `<package project="…">` attribute up the inheritance chain.

2. **Pick the SLES-compatible source channel.** For SLES overlay work, default to
   `SUSE:SLE-15-SP<n>:Update/<pkg>`. Factory only if you specifically want Tumbleweed-newest and
   have audited that your buildroot can swallow the newer toolchain BRs. Never `SP<n>:GA` for a
   backport workaround — that's the version that _caused_ the ABI break.

3. **Use the 4-arg `osc branch` to rename in the target.**
   `osc branch <src-prj> <src-pkg>
   <tgt-prj> <tgt-pkg>` keeps the source-side name where openSUSE
   / SUSE want it (`expat`) and the target-side name where your converger / runbook / harness want
   it (`libexpat`). The `_link` still resolves correctly because OBS records both names.

4. **`_buildenv` is the only authoritative answer to "what was in the buildroot."** Not
   `osc
   results`, not `osc buildlog`, not `binaryversions`. `_buildenv` is generated by the build
   and ships alongside the RPMs in `getbinaries -d`; grep it for the package you care about and the
   `project="…"` attribute tells you exactly where it came from.

5. **Auto-rebuilds are normal — don't `osc rebuild` over them.** When you publish a new version of a
   dependency, OBS re-schedules consumers automatically. Issuing `osc rebuild` while one is
   in-flight cancels it. Always check state first; only `osc rebuild` if the lane is in a terminal
   state (`succeeded` / `failed` / `unresolvable`) and you actually want to retry.

6. **Pre-flight every consumer lane's `binaryversions` before tightening a BR**, even if you're only
   targeting one lane. A BR inside a `%if 0%{?sle_version} >= 150400` arm fires on SP4/5/6/7
   simultaneously; one lane lacking the new library is enough to regress an otherwise-green project.

7. **`osc getbinaries -d <dir>`, not `osc getbinaries … <dir>`.** The 5th positional is a single
   filename, not a destdir. Repeating this rule because it's universal across `osc` workflows, not
   specific to this case study.

## Happy path — what this would have looked like end-to-end

```bash
# 1. Discover the source-pkg name (one API call).
osc -A <api> api \
  '/search/published/binary/id?match=@name="libexpat1"+and+@project="SUSE:SLE-15-SP7:Update"'
# → package="expat", version="2.7.1"

# 2. Branch the SP-Update package into the home project, renaming target → libexpat.
osc -A <api> branch \
  SUSE:SLE-15-SP7:Update expat \
  <home-project> libexpat

# 3. Wait for it to publish on the lane you care about.
osc -A <api> results --watch <home-project> libexpat

# 4. Confirm the home project now publishes libexpat1 at the version you need.
osc -A <api> api \
  '/build/<home-project>/<lane>/<arch>/_repository?view=binaryversions&binary=libexpat1&withevr=1'

# 5. Let the satellite auto-rebuild (it will, because libexpat is one of its BRs). Check state.
osc -A <api> results <home-project> <satellite-pkg>

# 6. Verify the buildroot really used your libexpat, not the upstream :GA one.
mkdir -p /tmp/verify/binaries && cd /tmp/verify && rm -rf binaries/*
osc -A <api> getbinaries -d binaries <home-project> <satellite-pkg> <lane> <arch>
grep 'bdep name="libexpat1"' binaries/_buildenv      # project="<home-project>"  ← must be your project
rpm -qpl binaries/<satellite-pkg>-*.<arch>.rpm | grep site-packages   # /usr/lib/python3.11/... only
```

Six commands, zero source-side spec edits, zero patch rewrites. The only mutation to the home
project is the single `osc branch`.

## Final result

- `libexpat` published `2.7.1-150700.3.14.1` on `SLE_15_SP7` in the home project, with the
  CVE-2025-59375 backport patch inherited automatically from `SUSE:SLE-15-SP7:Update/expat`.
  CVE-2026 follow-ups (`-24515`, `-25210`, `-32776`, `-32777`, `-32778`) are also in-tree by
  reference.
- `SUSE:SLE-15-SP7:Update/expat`'s 2.7.1 source spec is multi-lane compatible, so SP4 / SP5 / SP6 /
  SP7 all built and published the appropriate `2.7.1-1504xx/1505xx/1506xx/1507xx.3.14.1` libexpat1
  RPMs in the home project.
- `<satellite-pkg>` SP7 auto-rebuilt to `succeeded` with no spec/patch changes. Payload landed under
  `/usr/lib/python3.11/site-packages/...`. `_buildenv` confirmed `libexpat1` came from
  `project="<home-project>"`, not `SUSE:SLE-15-SP7:GA`.
- One out-of-scope side effect: `SLE_12_SP5/libexpat = failed`. The 2.7.1 spec needs build
  prerequisites the SLE 12 base lane doesn't carry. The satellite's `SLE_12_SP5` lane stayed
  `succeeded` because its python311 BR arm is gated to `sle_version >= 150400` and doesn't fire on
  SLE 12. Solution if you want a clean project: drop `SLE_12_SP5` from libexpat's `meta pkg`
  repositories.

## Cross-cutting concerns

1. **The libexpat BR can stay commented out.** The satellite succeeds because OBS's resolver prefers
   same-project published binaries. The BR's role is fail-fast guard against a future regression
   where libexpat stops publishing. Un-commenting it is hardening, not a prerequisite. When you do
   un-comment, pre-flight every lane's `binaryversions` first (rule 6 above).

2. **CVE patches inherit automatically through `_link`.** The home project's `libexpat` is
   `_link`-based — every time `SUSE:SLE-15-SP7:Update/expat` lands a new CVE patch upstream, the
   home project picks it up on the next rebuild. No maintenance burden in steady state.

3. **`SUSE:SLE-15-SP<n>:Update` reachability requires SUSE creds.** The probe above (and the branch)
   work for SUSE employees / customers with valid OBS auth. For public/community consumers, the
   fallback is `openSUSE:Leap:15.<n>/expat` (which carries the same 2.7.1 + CVE patch on Leap 15.6)
   — same `osc branch` pattern, different source project.

## Hardening — activate the fail-fast `BuildRequires: libexpat1 >= 2.7.1` guard

The case study ends with the satellite green and `_buildenv` confirming the home-project
`libexpat1`. The build is **correct today** but **silent** — the satellite has no source-level
declaration of its dependency on the post-CVE ABI. If the home-project libexpat ever stops
publishing (project deleted, branch reverted, repository scope changed), the resolver silently falls
back to `SP<n>:GA`'s pre-CVE `libexpat1` 2.6.x. The satellite still builds and publishes; the
regression only surfaces at runtime when the installed payload tries to dlsym a 2.7-only symbol
(`XML_SetAllocTrackerActivationThreshold` in our case).

The fix is **one line in the satellite spec**: turn the latent fail-fast guard into an active BR.
The hardened satellite refuses to build (clean `unresolvable: nothing provides libexpat1 >= 2.7.1`)
the moment the home-project provider disappears, instead of silently regressing to a runtime
`ImportError`.

### When safe to activate

Activate the BR only when every lane it will fire on already publishes a satisfying `libexpat1` in
the home project. The pre-flight is one API call per lane (rule 6 in the case study above):

```bash
osc -A <api> api \
  '/build/<home-project>/<lane>/<arch>/_repository?view=binaryversions&binary=libexpat1&withevr=1'
```

Expected: `<binary name="libexpat1.rpm" evr="2.7.1-…" arch="<arch>"/>` on every lane the BR fires
on. `error="not available"` on any lane → do **not** activate; either tighten the BR's `%if` arm
(SP-only) or publish `libexpat1` on the missing lane first.

### Activation diff (one-line)

For a patch that carries the BR in commented form (the pattern this case study's project ships by
default — kept commented while older SPs lacked a published libexpat):

```bash
sed -i 's|^+# BuildRequires: libexpat1 >= 2.7.2.*|+BuildRequires: libexpat1 >= 2.7.1|' \
  <overlay>.patch
```

The version literal **must** match what SUSE actually shipped — for CVE-2025-59375 that's a 2.7.1
backport, not a 2.7.2 rebase (case study rule 1: "Probe before encoding"). Commit with `osc vc`

- `osc ci`, then watch the satellite rebuild settle with
  `osc results --watch <home-project> <satellite-pkg>`.

### Cross-lane risk and the escalate-first rule

If the BR sits inside a multi-lane `%if 0%{?sle_version} >= 150400 && < 160000` arm and one of the
other lanes lacks a satisfying `libexpat1`, that lane regresses to
`unresolvable: nothing
provides libexpat1 >= 2.7.1`. **Don't** patch around this from inside the
activation step — escalate first so the operator picks the right scoping:

- Add a nested SP-only conditional (`%if 0%{?sle_version} >= 150700`) inside the existing arm to
  scope the BR down.
- Or publish the missing lane's `libexpat1` first (extend the home-project `libexpat` package's
  `meta prj` to cover the missing repository).

Both alter project-scoped state and must be user-authorized — the agent must not pick a scope on its
own.

### What about the rebuild's `blocked: <dep>` flicker?

After `osc ci`, the satellite often spends 5–15 min in `blocked: <dep-name>` (e.g.
`blocked:
libexpat1`) while the dependency itself goes through an `unchanged` republish cycle.
**This is transient, not terminal** — per the
[OBS user guide on scheduling and dispatching](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-build-scheduling-and-dispatching):
_"Usually the build of a package gets blocked when a package required to build it is still building
at the moment."_ The scheduler auto-resolves it when the upstream binary settles. Flickering between
`outdated` and `blocked` is normal tick behavior, not pathology.

Only escalate to `osc rebuild` if you exceed ~20 min AND
`osc jobhistory <home-project>
<satellite-pkg> <lane> <arch>` confirms no build job was ever created
for the lane (scheduler missed the change). Premature `osc rebuild` cancels the in-flight
auto-rebuild — see rule 5 above.

## Why this case study matters / when to consult it

Reach for this case study any time you need to **override a buildroot library at a higher version
than the base SP ships**, especially when the upstream binary RPM name differs from its source
package name (very common for `lib<foo><N>` ↔ `<foo>` pairs). The recipe — discover source name,
pick the SLES-compatible Update channel, 4-arg branch with target-rename, verify with `_buildenv` —
generalizes to any same-project override (e.g. `libxml2`, `libssh4`, `libldap`, the entire
`lib<foo><N>` family).

See also:

- [`../libexpat-source-naming.md`](../libexpat-source-naming.md) — reference card with the
  binary-vs-source name convention, the authoritative probe, and the cross-project version /
  CVE-patch matrix. Use that when you need the recipe without the war-story prose.
- [`../setup-home-project-from-upstream.md`](../setup-home-project-from-upstream.md) — the
  branched-provider topology this case study extends.
- [`../common-mistakes-and-pitfalls.md`](../common-mistakes-and-pitfalls.md) — the wider catalog of
  `osc` foot-guns, including the binary-vs-source naming trap.
- [`01-broken-link-drift-after-patch-rename.md`](./01-broken-link-drift-after-patch-rename.md) —
  this case study's sibling, covering the source-tree drift that preceded the SP7 work in the same
  project.
