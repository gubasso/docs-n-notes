# Claude self-debug loop — driver architecture

> $claude-code $agent $loop $automation $obs $osc $packaging $runbook

A reusable design for a self-debugging loop driven by Claude Code that converges complex, multi-step
diagnostic procedures (buildroot resolution, ABI overrides, satellite republish chains, etc.) by
walking a per-target runbook to completion. Originally authored to converge SLES lanes in an OBS
overlay project, but the shape generalises to any "long-running, retry-heavy, branch-heavy"
operations workflow that pairs natural-language step interpretation with typed side-effecting
tooling.

Pair this design with the per-target runbook template at
[`../tools/osc-obs/runbook-template.md`](../tools/osc-obs/runbook-template.md) (the OBS-flavoured
shape), or adapt the same shape to your own domain.

Placeholders used below:

- `<runbook-root>` — directory containing per-target runbook markdown files (e.g. `sp4.md`,
  `sp6.md`, `sp7.md`).
- `<log-dir>` — directory the loop writes its per-run logs to (`<YYYYMMDD-HHMMSS>-<topic>.md`).
- `<skill-name>` — name of the Claude Code skill that owns the domain's side-effecting verbs
  (`osc-obs`, `kubectl`, `terraform`, whatever).

## Driver — runbook IS the state machine

The loop's input is a per-target runbook markdown file. Each runbook contains a sequence of
`## Step N` sections with this exact shape:

- A goal sentence describing what the step is trying to change.
- One or more fenced bash blocks of commands to run (executed via the domain skill).
- A `**Stop criterion:**` block — the success condition for this step.
- A `**Branch points:**` block — a bulleted list of `<outcome> → <action>` rules.

These three blocks form the loop's transition table. The runbook prose IS the state machine — no
separate schema needs to be declared or parsed.

## Implementation — not new code

The loop is NOT new Python (or Go, or anything) in the consumer project. It runs as a Claude Code
session driven by:

- The domain `<skill-name>` skill (Markdown file with optional helper scripts) that owns every
  side-effecting verb and the edit-fence instruction. Authoritative for what the loop is allowed to
  touch.
- A top-level prompt that names the runbook, the target / lane, and `<log-dir>`.

Loop logic (parse → execute → branch → log) stays on the model side where natural-language step
interpretation, structured-output extraction, web research, and decision-making belong. The skill
provides the typed surface for the side effects.

## Capabilities required

- **Command execution** in the loop's working environment (via the domain skill).
- **Output parsing** — extract structured findings from the domain's tooling output (`osc results`,
  `kubectl get`, `terraform plan`, etc.). The skill returns a typed
  `{outcome, summary, branch_points,
  raw_excerpt}` object.
- **Web research** — query upstream docs / advisories / changelogs when the runbook calls for it.
- **File editing** — apply targeted edits to in-domain files inside the skill's edit fence (NEVER
  consumer-project source).
- **Long-running watch** — when the runbook calls for a "wait for X to settle" step, the skill
  issues the domain's blocking watch command (`osc results --watch`, `kubectl wait`, etc.). The loop
  must use the blocking form, not poll, to avoid cancelling in-flight server-side work.
- **Branch on outcome** — read the skill's structured `outcome` / `branch_points` fields and match
  them against the runbook's `Branch points`.

## Log persistence — try-error history

Every loop run appends one markdown under `<log-dir>/<YYYYMMDD-HHMMSS>-<target>.md` with these
sections:

- Header (status, target, branch, date).
- Target (what's being converged — project / package / repository / etc.).
- Failure signature (verbatim error text + source location).
- Diagnosis (bucket classification — which class of failure).
- Definitive fix (the minimal diff that landed, and where).
- Cross-cutting concerns (unrelated issues surfaced during the run).
- Agent runs that produced this diagnosis.

**Before** re-trying a step that previously failed, the loop reads prior log files in `<log-dir>/`
and any escalation ladder the runbook references. If the same `{step, failure-signature}` pair
already appears, the loop must pick a different strategy or escalate — never repeat the same edit.

## Failure handling

- **Unexpected branch point** (step's stop criterion missed AND no `Branch points` entry matches the
  actual outcome) → consult fallback options if the runbook references any; if none apply, escalate
  to human. Do NOT invent a branch action.
- **Same step fails N times in a row** (N = 3, configurable) → escalate. Do not loop on the same
  failing step indefinitely.
- **Web research returns no fresh data** → log the gap and proceed with the runbook's documented
  assumptions; do not invent.
- **Environment loses connectivity** → pause the loop, surface, do not retry-forever.

## Budget guardrails

- **Wall-clock cap per step** — e.g. default 30 min, override per step in the runbook header for
  long-running operations (build waits, large branches).
- **Token budget cap per loop invocation** — on approach, summarize state and hand off to the next
  invocation rather than truncating mid-step.
- **Skill-level edit fence** — the skill's preamble enumerates the paths the loop is allowed to
  edit. Anything else is off-limits; the skill must stop and surface to the human.

## Loop shape (sketch)

```text
for step in parse_runbook(runbook_for_target):
    log("entering", step.number, step.title)
    if previously_failed_signature(step, log_dir):
        consult fallback_ladder() or escalate
        continue
    for cmd in step.commands:
        result = skill.run(cmd)
        record(result)
    finding = skill.evaluate(step.stop_criterion)
    if finding.outcome == "succeeded":
        continue
    action = match_branch_point(step.branch_points, finding)
    if action is None:
        escalate("no matching branch point", step, finding)
        return
    apply(action)   # e.g. re-run, edit-and-retry, jump-to-step-N
```

## Hand-off

When a runbook's final `Stop criterion` is met, the loop writes a closing log entry and stops. The
human then runs the matching verification cursor (e.g. end-to-end test, downstream consumer trigger)
and ticks the relevant tracking entry.

## How to invoke

```text
claude --prompt "Run the <target> runbook to completion.
  Target: <target>.
  Runbook: <runbook-root>/<target>.md.
  Log under <log-dir>/."
```

## When to use this pattern

- **Long-running multi-step domain operations** with rich branch semantics (OBS build convergence,
  k8s migration sequences, multi-environment deploys with rollback paths).
- **Retry-heavy workflows** where the right fix depends on the exact failure signature, and a
  generic "rerun on failure" loop loses information.
- **Workflows where the procedure itself evolves** — the runbook markdown is the source of truth,
  edited by humans, consumed by the loop. No code change needed to alter the procedure.

## When NOT to use it

- **Trivial happy-path operations** that succeed first time — a simple bash script wrapped in
  `set -e` is faster, cheaper, and more transparent.
- **Operations where the side effects are dangerous to retry** (untracked filesystem writes,
  destructive DB ops) — the skill's edit fence must be airtight, or the cost of a misfire is too
  high.
- **Operations where the structured output isn't reliably parseable** by an LLM — if the domain
  tooling returns unparsable text and outcomes can't be reliably classified, branching becomes
  hallucination.

## See also

- [`../tools/osc-obs/runbook-template.md`](../tools/osc-obs/runbook-template.md) — OBS-flavoured
  per-lane runbook template that this driver consumes.
- [`../tools/osc-obs/README.md`](../tools/osc-obs/README.md) — `osc-obs` reference subtree (the
  side-effecting skill's reference docs).
