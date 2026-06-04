# OBS overlay per-lane convergence — runbook template

> $obs $osc $opensuse $sles $packaging $runbook $claude-loop

Generic shape for a per-lane convergence runbook driven by a Claude self-debug loop (see
[`../../workflows/claude-self-debug-loop.md`](../../workflows/claude-self-debug-loop.md) for the
loop driver this template feeds).

Copy this file into your OBS overlay project's `docs/` tree (or your loop's input directory) as
`sp<N>.md` and fill in. The section headers and block names are the loop's contract — keep them
verbatim. The `Stop criterion` + `Branch points` blocks under each `## Step N` form the loop's state
machine: a step "succeeds" when its stop criterion is met; otherwise the loop matches the actual
outcome against a `Branch points` entry and follows the action there.

Placeholders used below:

- `<home-project>` — your home / test OBS project namespace, e.g. `home:<user>:<project>-test`.
- `<obs-workspace>` — the host path where `osc co` checkouts live, e.g. `~/Projects/_obs-work/`.
- `<bootstrap-script>` — your project's idempotent OBS-side converger (creates the project,
  satellite `_link`s, branched providers, etc.).
- `<loop-library>` — the loop's append-only reference cache, e.g. `<loop-dir>/library/`. Generic
  versions of the same notes live in the parent `osc-obs/` subtree alongside this template.
- `<log-dir>` — where the loop writes its per-run log markdowns, named
  `<YYYYMMDD-HHMMSS>-<topic>.md`.

---

# Runbook template — SLE 15 SP<N>

> Diagnostics rule: on any error / branch point / retry, the agent MUST fetch authoritative sources
> (local `~/DocsNNotes/tech/tools/osc-obs/` → in-project reference docs → `<loop-library>/` →
> `osc --help` / API probes → upstream OBS / SUSE / rpm.org URLs) before proposing a fix, and
> persist any reusable finding back to both `<loop-library>/<topic>.md` and
> `~/DocsNNotes/tech/tools/osc-obs/<topic>.md`. See the Diagnostics protocol section of the
> `osc-obs` Claude Code skill.

## Lane

`SLE_15_SP<N>` / `x86_64`

## Goal

(One paragraph: what state we are converging the OBS test project package set to, and the cross-ABI
/ install assertion that proves it.)

## Preconditions

- Bootstrap has run: `<bootstrap-script>` was last executed and `<home-project>` is in its declared
  shape.
- OBS workspace at `<obs-workspace>/<home-project>/` is read-write and contains the satellite
  package checkouts.

## Step 0 — diagnostic snapshot

(Read-only probes that confirm the starting state. Always safe to re-run.)

```bash
osc -A https://api.opensuse.org results <home-project>
```

**Stop criterion:** snapshot recorded; ready to proceed.

**Branch points:**

- All lanes already `succeeded` → no work; record a "no-op" log entry and stop.
- The target lane shows `building` / `scheduled` → wait via `osc results --watch <prj> <pkg>`, then
  re-evaluate Step 0. Never proceed past Step 0 with an in-flight build — a downstream `osc rebuild`
  could cancel it.
- The target lane shows `unresolvable` or `failed` → proceed to Step 1.
- The target lane (and typically every sibling lane) shows `broken` → OBS link/source drift,
  pre-build. Recover per `~/DocsNNotes/tech/tools/osc-obs/broken-state-link-drift.md` (re-run
  `<bootstrap-script>` if it `osc rm`s orphan patches; or the explicit
  `osc add <new>.patch && osc rm <old>.patch &&
  osc ci -m '…'` sequence in the workspace).
  Re-evaluate Step 0 once the lane leaves `broken`. Never branch on `broken` as if it were
  `unresolvable` / `failed`; the resolver and build never ran.
- The target lane shows `blocked: <dep>` → scheduler-waiting on a sibling-package republish, not
  terminal. Default wait is 15–20 min; do **NOT** `osc rebuild` (cancels the in-flight
  auto-rebuild). See `~/DocsNNotes/tech/tools/osc-obs/blocked-state-is-transient.md`.

## Step 1 — (first remediation)

(Goal sentence — what this step is trying to change.)

```bash
# Commands here, all routed via the osc-obs skill. Edits only to files
# under <obs-workspace>/<home-project>/<package>/.
```

**Stop criterion:** (What "done" looks like after this step.)

**Branch points:**

- `<outcome label> → <action>` (e.g., "`succeeded` → proceed to Step 2".)
- ...

## Step N — final verification

(End-to-end check; the assertion that proves the lane is fixed. Usually an
`osc getbinaries -d <dir>` followed by an `rpm -qpl` / `grep _buildenv` probe — see the OBS overlay
verbal of this template for the canonical commands.)

**Stop criterion:** (e.g., "every `site-packages` line shows the expected python ABI; the cross-ABI
assertion in the consumer project does not fire when its matching test cursor is run.")

## Log on completion

Write `<log-dir>/<YYYYMMDD-HHMMSS>-sp<N>.md` per the structure documented in
[`../../workflows/claude-self-debug-loop.md`](../../workflows/claude-self-debug-loop.md). Always
write the log file (success or failure) so the next run sees what was tried.

## See also

- [`README.md`](README.md) — `osc-obs` reference subtree index.
- [`broken-state-link-drift.md`](broken-state-link-drift.md) — pre-build link/source drift recovery.
- [`blocked-state-is-transient.md`](blocked-state-is-transient.md) — `blocked: <dep>` is not
  terminal.
- [`libexpat-source-naming.md`](libexpat-source-naming.md) — binary-vs-source naming convention.
- [`sle-update-pool-vs-standard.md`](sle-update-pool-vs-standard.md) — `pool` vs `standard` for
  Update projects.
- [`../../workflows/claude-self-debug-loop.md`](../../workflows/claude-self-debug-loop.md) — loop
  driver this template feeds.
