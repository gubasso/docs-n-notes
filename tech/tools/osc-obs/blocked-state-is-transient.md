# OBS `blocked: <dep>` is a transient scheduler state, not terminal

> Topic: when an `osc results` line shows
> `<repo>, <arch>, <pkg>, building, True, blocked, <dep-name>` for an extended period, the build is
> **waiting** for its dependency's binaries to settle in the repository — not stuck. The OBS
> scheduler auto-resolves it. Premature `osc rebuild` cancels the in-flight auto-rebuild and resets
> the timer.

## TL;DR

- `blocked: <dep>` means: "a package required to build me (`<dep>`) is still building / republishing
  right now."
- The scheduler unblocks automatically when `<dep>`'s binaries re-publish to the repository index.
- Flickering between `outdated` and `blocked` between scheduler ticks is **normal**, not
  pathological — the scheduler re-evaluates whether the newly-published binary supersedes the last
  build result.
- `dirty=True` alongside `blocked` means the repo's binaries are not yet republished after the
  source change; downstream consumers see the last-published snapshot until republish lands.
- Default wait: 15–20 min. Only escalate to `osc rebuild` if BOTH exceed 20 min AND `osc jobhistory`
  shows zero jobs were ever created for the lane (i.e. scheduler missed the change entirely).

## Worked example — typical state sequence after a BR-activation commit

After committing a satellite spec/patch change that tightens a `BuildRequires:` against a
same-project branched provider, the satellite's lane typically traverses:

```text
scheduled → blocked: <dep> → outdated → blocked: <dep>
  → building → finished → published / succeeded
```

CSV snapshot during the `blocked` window:

```csv
"<lane>","<arch>","<satellite-pkg>","building","True","blocked","<dep>"
```

The companion `<dep>` package on the same lane often shows
`building, dirty=True, finished/unchanged` — OBS's internal "binaries are valid but the repository
index is being recomputed" cycle. A `binaryversions` probe against `<dep>` consistently returns the
same evr throughout, confirming the published binary itself is stable; only the index/state is
churning. Worker-queue contention on a specific lane can extend this window past the expected 5–10
min — siblings on other lanes typically complete faster.

## Decision rule for the loop

| Observation                                             | Action                                                                                                                                                                        |
| ------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `blocked: <dep>` < 15 min                               | Wait. Normal.                                                                                                                                                                 |
| `blocked: <dep>` 15–20 min                              | Wait. Check upstream dep state via `osc results <home-project> <dep-pkg>` to confirm it's near settling.                                                                      |
| `blocked: <dep>` > 20 min                               | Probe `osc jobhistory <home-project> <pkg> <lane> <arch>`. If a job exists and is mid-build, keep waiting. If zero jobs, scheduler missed the change → safe to `osc rebuild`. |
| `blocked: <dep>` > 60 min with no upstream-dep progress | Escalate. Suspect scheduler stall (rare). Surface to the user, do NOT spam `osc rebuild`.                                                                                     |

## Sources

- [OBS User Guide: Build Scheduling and Dispatching](https://openbuildservice.org/help/manuals/obs-user-guide/cha-obs-build-scheduling-and-dispatching)
  — _"Usually the build of a package gets blocked when a package required to build it is still
  building at the moment."_
- [openSUSE forums — openSUSE_Factory 'blocked'](https://forums.opensuse.org/t/opensuse-factory-blocked/29947)
  — community confirmation that the state auto-resolves; no manual intervention is needed in the
  steady-state case.
- [openSUSE/obs-build issue #824 — Arch Linux DoD download stalls](https://github.com/openSUSE/obs-build/issues/824)
  — documented edge case where DoD (Download-on-Demand) repository metadata fetch failures can leave
  packages indefinitely blocked. Not applicable to most home-project workflows (no DoD), but the
  failure mode is worth knowing if it ever appears.

## Cross-references

- [`case-studies/02-libexpat-abi-override-via-sles-update-branch.md`](case-studies/02-libexpat-abi-override-via-sles-update-branch.md)
  — has a short callout summarizing this rule in the context of activating a fail-fast BR after a
  buildroot ABI override (the "Hardening" section, "What about the rebuild's `blocked: <dep>`
  flicker?" sub-bullet).
- Any per-lane runbook that watches a satellite rebuild after a dependency change should treat
  `blocked: <dep>` the same way it treats `building` / `scheduled`: wait via `osc results --watch`
  rather than re-trigger.
