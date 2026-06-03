# Case study 01 — `broken` lane state after renaming an overlay patch

> <https://en.opensuse.org/openSUSE:Build_Service_Concept_SourceService>
> <https://en.opensuse.org/openSUSE:OSC>
> <https://openbuildservice.org/help/manuals/obs-user-guide/cha.obs.source_service.html>

## TL;DR

When you widen / rename an overlay `*.patch` in a `_link`-based home-project package, OBS will only
expand the link if the source tree carries the file `_link.apply` actually names. A converger script
that **`osc add`s the new patch but never `osc rm`s the old one** leaves the source tree
inconsistent with `_link.apply`. Every consumer lane goes `broken: patch '<new>' does not exist`
**simultaneously**, pre-build, with no resolver output and no `buildlog` — distinct from
`unresolvable` (resolver) and `failed` (build). Recovery is one workspace commit:
`osc add <new>.patch && osc rm <old>.patch && osc ci -m "Sync source tree with _link…"`. Prevention
is making the converger enumerate server-tracked `*.patch` files and `osc rm` any that aren't the
current one **before** committing.

## Goal

Bring `<satellite-pkg>` on `SLE_15_SP6` to `succeeded`, with its installed payload landing under
`/usr/lib/python3.11/site-packages/` (instead of the system py3.6) so a downstream consumer's
cross-ABI assertion stops firing on SP6 PAYG LTSS images.

The bootstrap script lays down a widened overlay patch (gate `>= 150400`, libexpat BR commented out)
and a `_link` whose `apply name="…sp4plus.patch"` points at that widened patch. The runbook verifies
that and waits for the lane to go green.

## Challenge — what you'll trip over

The runbook's Step 0 table enumerates `succeeded` / `unresolvable` / `failed` / `building` /
`scheduled`. The lane was **`broken`**. That state had not been encountered before; it has its own
semantics, its own diagnostic recipe, and its own recovery — none of which look like the other
states.

Specifically: `broken` is **pre-build**. The OBS scheduler refuses to schedule the lane because the
_source service_ (the layer that expands a `_link` into a real source tree) cannot reconcile
`_link.apply` against what's tracked in the package. So there's no `buildinfo` to inspect, no
`buildlog` to tail, no resolver candidate list. The familiar diagnostic ladder (`buildinfo` →
`buildlog` → fix BR) doesn't apply.

| State          | What ran    | What's wrong                               | Where to look                               |
| -------------- | ----------- | ------------------------------------------ | ------------------------------------------- |
| `unresolvable` | resolver    | a `BuildRequires` can't be satisfied       | `buildinfo`                                 |
| `failed`       | build       | configure / compile / link / `%check` died | `buildlog`                                  |
| **`broken`**   | **nothing** | **source service can't expand `_link`**    | `osc results -v`, `?expand=1` HTTP 400 body |

## What went wrong (timeline)

1. **Overlay-patch evolution.** The original overlay patch was gated on `sle_version >= 150700` (SP7
   only). Goal: widen the gate so SP4-SP7 lanes activate the python311 pin too. The intended commit
   (call it rev 9) was supposed to (a) drop the old `<old>.patch`, (b) upload the new widened
   `<new>.patch`, (c) update `_link` so `<apply name="<new>.patch"/>`. Same commit, no intermediate
   broken state.

2. **The commit landed half-done.** Rev 9 updated `_link` to reference `<new>.patch` but did NOT
   upload `<new>.patch` and did NOT remove `<old>.patch`. Server source listing for the package
   afterward:

   | File          | rev 8 (last good)                  | rev 9 (broken)                     |
   | ------------- | ---------------------------------- | ---------------------------------- |
   | `_link`       | md5 X (`apply name="<old>.patch"`) | md5 Y (`apply name="<new>.patch"`) |
   | `<old>.patch` | present                            | **still present**                  |
   | `<new>.patch` | absent                             | **still absent**                   |

   `_link.apply` now references a file that has never existed in the source tree.

3. **Every lane went `broken` simultaneously.** Because the source service runs upstream of any
   per-lane scheduling, the failure is project-wide, not per-lane. `osc results` showed every lane
   reporting the same message:

   ```text
   SLE_15_SP7  x86_64  <satellite-pkg>  broken: patch '<new>.patch' does not exist
   SLE_15_SP6  x86_64  <satellite-pkg>  broken: patch '<new>.patch' does not exist
   SLE_15_SP5  x86_64  <satellite-pkg>  broken: patch '<new>.patch' does not exist
   SLE_15_SP4  x86_64  <satellite-pkg>  broken: patch '<new>.patch' does not exist
   SLE_12_SP5  x86_64  <satellite-pkg>  broken: patch '<new>.patch' does not exist
   ```

   `osc api '/source/<prj>/<pkg>?expand=1'` returned HTTP 400 with the same message in the body.
   That's the authoritative confirmation: it's source-service link expansion failing, not a build
   problem.

4. **Local workspace looked fine.** `osc status` in the package's checkout reported `_link` clean
   (matches server) and `<new>.patch` showing as `?` (untracked) on disk. The script had copied the
   new patch into the workspace, never registered it via `osc add`, and never `osc rm`'d the old
   one. The old `<old>.patch` showed as `!` (server-tracked, missing locally) — the script had
   `rm`-ed it from the workspace but never `osc rm`-ed it from the server.

5. **The runbook escalated.** Its Step 0 had no `broken` rule, and the skill's loop contract says
   "if no rule matches → escalate." That was the right call — guessing here would have invited a
   destructive `osc revert` or similar.

### Mistakes / foot-guns hit along the way

These are smaller items that ate time during the run, all preserved here so the next session doesn't
burn the same hours.

1. **`osc results` summary doesn't show the message.** The non-verbose form is just
   `<lane>  <arch>  <pkg>  broken` — without the precise reason. **Always use `osc results -v`** for
   `broken` lanes; the message lives in the status column there.
   (`osc api '/source/<prj>/<pkg>?expand=1'` is the orthogonal confirmation — same message,
   different code path.)

2. **`osc getbinaries <prj> <pkg> <repo> <arch> binaries` silently no-ops.** The fifth positional in
   `osc getbinaries`'s grammar is **`[FILE]`** — a single filename to download from the per-arch
   binaries directory — not a destination directory. Passing `binaries` makes osc try to download a
   file called `binaries`, gets nothing, exits 0. The verification grep then runs on an empty
   directory and "passes" without proving anything. **Use `-d <dir>` for a destination directory.**

3. **`osc vc` silently skips the changelog if `obs-build` is missing.** `osc vc -m …` shells out to
   `/usr/lib/build/vc` — provided by the `obs-build` package, NOT pulled in by `osc` itself. In a
   stripped-down container, `osc vc` errors but `osc ci` runs anyway, so the commit lands with no
   `.changes` entry. For a home/test project that's tolerable; for a real package-maintenance flow
   it isn't. **Either install `obs-build` in the build container or make the converger fail loudly
   when `osc vc` fails**, don't let the changelog quietly go missing.

## What I did to fix it

One workspace commit:

```bash
cd "${WORKSPACE}/<prj>/<pkg>"

osc -A <api> add <new>.patch       # workspace `?` → `A`
osc -A <api> rm  <old>.patch       # workspace `!` (server-tracked, locally missing) → `D`
osc -A <api> ci  -m "Sync source tree with _link: add <new>.patch, drop <old>.patch (recover from broken link state)"
```

`osc rm` accepts a locally-missing-but-server-tracked file (`!` in `osc status`) without `--force`.
Lanes transitioned `broken` → `scheduled` → `building` → `succeeded` within minutes on the lanes
that could actually build the satellite (SP6 / SP5 / SP4 / 12_SP5 in this case; SP7 had its own
separate libexpat issue covered in case study 02).

Bootstrap script was then patched (out of the original edit fence, with separate user authorization)
to enumerate server-tracked `*.patch` files and `osc rm` any that aren't the current one **before**
committing — closing the regression mode that produced rev 9. The fix pattern:

```bash
# inside the converger's ensure-satellite function, BEFORE the new osc add / ci:
while IFS= read -r tracked_patch; do
  [[ -z "${tracked_patch}" ]] && continue
  [[ "${tracked_patch}" == "${patch_name}" ]] && continue
  case "${tracked_patch}" in
    *.patch)
      osc rm "${tracked_patch}" 2>/dev/null \
        || osc rm --force "${tracked_patch}"
      ;;
  esac
done < <(osc ls "${HOME_PROJECT}" "${pkg}" 2>/dev/null || true)
```

Server-side, this turns "rename a patch" into a single idempotent invocation of the converger;
manually it stays a two-call `osc add` / `osc rm` recovery.

## Correct path next time — the rule distilled

1. **Patch evolution is a paired operation.** Renaming or replacing an overlay patch is
   `osc add
   new && osc rm old && osc ci` in one commit. Never split it across two commits; never
   let your converger automate one half.

2. **Converger must enumerate-and-prune, not just append.** Any script that overwrites `_link` and
   drops in `${patch_name}` is incomplete if it doesn't first enumerate server-tracked `*.patch` and
   `osc rm` orphans. Asymmetric `osc add` is a foot-gun.

3. **Every runbook's Step 0 must list `broken` as a state.** It is not exotic — it's a routine
   pre-build OBS state with its own recovery. Treat it as a peer of `unresolvable` / `failed`, not a
   surprise. Recovery is in [`../broken-state-link-drift.md`](../broken-state-link-drift.md).

4. **Diagnose `broken` with the two-call recipe**, not by inferring from `osc results`'s default
   summary:

   ```bash
   osc -A <api> results -v <prj> <pkg>                               # message in status column
   osc -A <api> api '/source/<prj>/<pkg>?expand=1' 2>&1 | head       # HTTP 400 body, same message
   osc -A <api> api '/source/<prj>/<pkg>'                            # what's actually tracked
   ( cd "${WORKSPACE}/<prj>/<pkg>" && osc -A <api> status )          # workspace view; compare to _link.apply
   ```

5. **When you can't tell whether the workspace or the server is the source of truth**, the server
   wins. The workspace can have files (untracked, modified, missing) that don't match the server's
   tracked set. `osc status` discrepancies (`?` for untracked, `!` for missing-but-tracked) are
   exactly the signal you want — they point at what needs `osc add` or `osc rm`.

6. **Don't trust an `osc results --watch` that you've never paired with a `getbinaries -d` payload
   inspection.** Build-succeeded ≠ payload-correct. The `python3.11`-vs-`python3.6` site-packages
   check exists for a reason — see case study 02 §"Final result" for the actual probe sequence.

## Happy path — what this would have looked like end-to-end

Starting from a clean home project with the satellite already linked:

```bash
# 1. Edit the overlay patch in your converger's source-of-truth dir.
$EDITOR scripts/obs-overlay/patches/<new>.patch

# 2. Update _link.tmpl so <apply name="<new>.patch"/>.
$EDITOR scripts/obs-overlay/_link.tmpl

# 3. Run the converger. The patched ensure-satellite enumerates and prunes orphans, then commits.
bash scripts/<overlay-bootstrap>.sh

# 4. Watch the lane settle.
osc -A <api> results --watch <prj> <pkg>

# 5. Verify payload ABI on the lane you care about.
mkdir -p /tmp/verify/binaries && cd /tmp/verify && rm -rf binaries/*
osc -A <api> getbinaries -d binaries <prj> <pkg> <repo> <arch>
rpm -qpl binaries/<pkg>-*.<arch>.rpm | grep site-packages   # every line should be python3.11/, not 3.6/
```

That's six commands, zero `broken` states, zero workspace surgery. The whole loop above is what the
runbook's Step 0 → Step 4 reduces to when nothing has drifted.

## Final result

- All five lanes left `broken` within seconds of the recovery commit.
- `SLE_15_SP6` reached `finished: succeeded` within minutes.
- Payload verification: `rpm -qpl <pkg>-*.x86_64.rpm | grep site-packages` → every line
  `/usr/lib/python3.11/site-packages/...`; byte-code is `cpython-311.pyc`; egg-info is
  `<pkg>-1.0.1-py3.11.egg-info`. **No `python3.6` lines.**
- SP4 separately surfaced `nothing provides python311-setuptools` — a _new_ symptom uncovered by
  widening the gate, not a regression of an already-green lane. Handed to a future per-SP runbook.
- SP7 surfaced the libexpat-ABI failure — see case study 02.

## Why this case study matters / when to consult it

Reach for this case study when **every lane of a home-project package flips to `broken`
simultaneously** right after you renamed, added, or replaced an overlay patch. The diagnostic recipe
nails the root cause in two commands and the recovery is one workspace commit. The deeper lesson —
converger scripts must enumerate-and-prune, not append-only — generalizes to any file type the
converger manages (additional patches, sub-spec snippets, generated tarballs).

See also:

- [`../broken-state-link-drift.md`](../broken-state-link-drift.md) — reference card with the full
  signature-to-cause table.
- [`../common-mistakes-and-pitfalls.md`](../common-mistakes-and-pitfalls.md) §2.2 — the "converger
  that `osc add`s but never `osc rm`s" anti-pattern in the wider catalog.
- [`../setup-home-project-from-upstream.md`](../setup-home-project-from-upstream.md) — the
  positive-path home-project setup walkthrough this case study is the failure-mode counterpart of.
