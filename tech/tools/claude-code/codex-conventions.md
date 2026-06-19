# Codex CLI Conventions

This file captures the verified Codex CLI conventions used by the `prex` workflow. Reuse these
patterns for future Claude-side orchestration work.

## Version Baseline

- **SoT:** `codex-session --version` (prints wrapper version, child binary path + version, active
  account).
- Skill workflows wire a profile per use case: each call site passes an explicit `--profile`
  (`deep`, `medium`, `low`, `quick`; see §Profile Strategy). No profile is auto-activated — a call
  that omits `--profile` runs on codex's stock built-in default. Codex v0.134+ has no in-file
  default-profile selector. **SoT:** `~/.config/codex-session/profiles/<name>.config.toml` (one file
  per profile, bare top-level keys, no `[profiles.<name>]` header).

## Wrapper: `codex-session`

Every Codex invocation in this document and in skill files uses `codex-session`, which composes a
config recipe, resolves the active account, sets `CODEX_HOME` to the per-account per-group session
directory, and passes through to the stock `codex` binary.

**Install:** `codex-session` must be on `PATH`. Verify with `codex-session --version`.

**Per-call lifecycle:** the wrapper resolves account + group-id, then sets
`CODEX_HOME=<state>/accounts/<account>/groups/<group-id>/`. Group-id resolution follows a 5-step
chain: `--group` flag > `CODEX_SESSION_GROUP` env > stable TTY id > PPID+starttime composite >
warned `pid-N` fallback. On resume, the wrapper restores the original group-id from the thread
index, so `exec resume <ID>` works across terminals and PIDs. The `pid-N` fallback emits a stderr
warning because the derived group is ephemeral and will differ on the next invocation.

**Account resolution:** `--account <name>` or `CODEX_SESSION_ACCOUNT=<name>` pins that account for
one invocation. With no flag/env, or with the value `auto`, codex-session uses quota-aware
auto-selection with automatic failover and no account cycling within a retry run. Exhaustion
surfaces as an explanatory `AutoExhausted` error. See `docs/auth-gate-spec.md` §3.2 for the full
specification. Omit `--account` for quota-aware selection, or pass `--account auto` explicitly as
the default alias.

The quota thresholds (50% five-hour / 10% weekly) are **soft penalty knees, not eligibility floors**
(changed 2026-06-02). An account below a knee is not blocked — it is heavily deprioritized in
scoring but still selectable, so the pool is used down to 0%. True exhaustion is API-driven: HTTP
429 → cooldown → rotate → `AutoExhausted`. See the "Quota knees & out-of-quota errors" section
below.

**Auth:** `auth.json` lives per-account at `<state>/accounts/<account>/auth.json` and is owned by
the wrapper. Codex writes refresh rotations in place. No write-back to the user's default codex
home.

**Wrapper-owned verbs:** `version`, `completion`, `config status`,
`config-recipe list|show|compose`, `doctor`, `account add|list|current|remove|refresh`,
`account quota`, `account cooldown show|clear`.

**Wrapper-owned global flags:** `--group`, `--account`, `--max-retries`, `--config-recipe`,
`--config`, `--format`, `--verbose`/`--quiet`/`--silent`, `--log-stderr`, `--log-format`.

**Argv pattern:** `codex-session exec ...` and
`codex-session exec [--profile <name>] resume <thread-id> ...`. The no-arg account form is the
quota-aware default; `--account auto` is the explicit alias, and `--account <name>` pins one
account. Each call site passes an explicit `--profile` for its use case (see §Profile Strategy);
`--profile` is an `exec`-level flag, so on a resume it goes before the `resume` subcommand.
codex-session itself never injects `--profile`:

```text
codex-session exec --profile medium ...
codex-session exec --profile medium resume <thread-id> ...
```

## Quota knees & out-of-quota errors

(Behavior as of 2026-06-02; codex-session repo plan `03-quota-soft-gate-and-messaging`.)

- **Soft knees, not floors.** `five_hour_threshold` (50%) and `weekly_floor` (10%) are _penalty
  knees_. Below-knee accounts get a dominant scoring penalty (`BELOW_KNEE_PENALTY`) so any
  above-knee account outranks any below-knee account, but below-knee accounts stay selectable and
  order among themselves by remaining quota. Accounts are used to 0%; selection no longer
  pre-emptively drops them.
- **`percent_left` means "% left".** All quota percentages are quota _remaining_, never quota
  _used_. A window at `0.0% left` is exhausted.
- **`NoEligible`** = no _usable_ account at all (no auth, all in active cooldown, or token expired).
  It is no longer raised merely because every account is below a knee.
- **`AutoExhausted`** = accounts were actually tried and all failed with 401/429 — true depletion.
  Its stderr block lists each account with a stable, parseable line shape:

  ```text
  • <id>  <state-phrase>  back in <dur> (<HH:MM UTC>)
  earliest available: <dur> (<HH:MM UTC>)
  ```

  The hint is **cause-aware**: `cooldown clear --all` is suggested only when cooldowns are the
  block, not for pure quota-window exhaustion (for that it gives the reset ETA). A machine channel
  mirrors per-account `state` / `five_hour_left` / `weekly_left` / `available_at_unix` plus a
  top-level `earliest_available_at_unix` via structured `tracing` fields.

### Resume is account-bound

`exec resume <thread-id>` can run **only** on the account that owns the thread — the rollout exists
only in that account's `CODEX_HOME`. The wrapper cannot rotate a resume to another account. When the
owner is quota-limited, the resume yields `ResumeBlocked` (exit 75), which:

- names the owning account, its blocking state, and its reset ETA;
- lists which _other_ accounts have quota now (with the caveat that they cannot continue _this_
  thread), or — if none are ready — every account's reset ETA.

Recovery for a `ResumeBlocked`: **wait** until the owner's reset time shown in the message and
re-run the resume, **or** start a fresh `exec` on an available account (new thread, no continuity).
Do not treat `ResumeBlocked` like a transient `"no rollout found"` error — it is a quota state, not
a missing-thread error, so the fresh-exec fallback is a deliberate continuity-losing choice, not an
automatic retry.

## Profile Strategy

Profile overrides live as separate files under `~/.config/codex-session/profiles/<name>.config.toml`
(codex v0.134+ contract). Each file contains bare top-level keys, no `[profiles.<name>]` header.
codex-session emits these 1:1 as siblings of the base `config.toml` in the session's `$CODEX_HOME/`.

Profiles are wired per use case — each skill call site passes an explicit `--profile`. codex itself
no longer supports an in-file default selector, and codex-session does not auto-activate any
profile, so a call that omits `--profile` runs on codex's stock built-in default (not a project
profile). The profiles are **tier-based** (model + effort tier, not workflow stage):

- **`medium`** — `gpt-5.5`, `medium` effort, full sandbox. The **quality default** for every
  substantive call: planning (`prex` stage 1), implementing a reviewed plan (`prex` stage 3, fresh
  `exec` or `resume`), and first-pass diff review (`review-loop` round 1). ≈ cost parity with
  `gpt-5.4 @ medium` after 5.5's token efficiency, for a clearly better result. A shared profile
  also keeps `exec resume` on the same model/effort across prex stages 1 → 3.
- **`low`** — `gpt-5.5`, `low` effort, full sandbox. Light tier for work whose reasoning was already
  done upstream: incremental re-checks of triaged fixes (`review-loop` rounds 2+) and read-only
  cross-check Q&A (claude `ask -c`). Never for multi-step reasoning.
- **`deep`** — `gpt-5.5`, `high` effort, full sandbox. **On-demand escalation only — never a skill
  default.** The human picks it case by case (stuck/looping runs, novel design, security-critical
  changes); `high` burns ~3–5× the reasoning tokens of `medium`. Before escalating, check whether a
  tighter prompt or context refresh fixes the failure for free.
- **`quick`** — `gpt-5.4-mini`, `medium` effort. Cheap fast Q&A and trivial text gen (codex-session
  `ask -f`, `gc`).
- **`ping`** — health-probe-only profile, used internally by `account health`.

> **Subscription-only policy.** These accounts authenticate via ChatGPT subscription (never API
> key). Every profile MUST pin a model selectable under ChatGPT-subscription auth — as of Codex CLI
> v0.135.0 that is **`gpt-5.5` / `gpt-5.4` / `gpt-5.4-mini`** (legacy general `gpt-5.2` reachable
> via `-m` only). The **`-codex` family is API-key-only**: pinning `gpt-5.3-codex` (or any
> `*-codex`) 400s with
> `The '<model>' model is not supported when using Codex with a ChatGPT account`. Never pin a
> `-codex` model. Model/pricing rationale now lives in the `cog` repo:
> `docs/reference/models-reference-codex.md`.

The wrapper's own composability lever is `--config-recipe` (commit 3117d8e). The `--profile` flag
passes through to stock codex unchanged. codex-session never injects `--profile` for user-facing
pass-through calls; wrapper-owned health probes (e.g. the heartbeat check in `account health`) pass
`--profile ping` internally.

References: `docs/upstream-codex.md` §F6b–§F6c (codex-session repo);
<https://developers.openai.com/codex/config-advanced#profiles>. Model/pricing/benchmark facts and
the derived cost × quality matrix + tier guidance behind these profiles now live in the `cog` repo:
`docs/reference/models-reference-codex.md` and `docs/reference/model-effort-policy.md` (with the
descriptive `docs/reference/model-effort-codex.toml`).

## Codex Skill Frontmatter & Per-Skill Profile Map

**Codex `SKILL.md` frontmatter supports only `name` and `description`.** There is no per-skill
`model` or `reasoning_effort` field — model + reasoning effort are session-global (`model`,
`model_reasoning_effort`) and are selected per call site via `--profile` (see §Profile Strategy). Do
**not** add `model:` / `effort:` / `profile:` keys to a Codex `SKILL.md`; they are not part of the
spec and are ignored. This differs from **Claude Code** skills, whose frontmatter _does_ support
`model` and `effort` — see [`skill-authoring/skill-spec.md`](./skill-authoring/skill-spec.md).

- **Sources:** <https://developers.openai.com/codex/skills> (Agent Skills),
  <https://developers.openai.com/codex/config-reference> (Configuration Reference).
- **Verified:** 2026-06-16. Re-fetch both sources and update this date when the spec changes.

Because a skill cannot self-select its model, the profile is chosen entirely **at launch** by
whoever invokes the skill — a human passing `--profile <tier>` at the `codex-session exec` prompt,
or an orchestrator that hardcodes it (e.g. `review-loop` per round, the `plan-writer-multi`
coordinator, the Claude `ask -c` runner). A `SKILL.md` body is just prompt content fed to an
already-running model; it cannot change the live model or reasoning effort. **Do not** put
`Recommended profile:` notes (or any `model`/`effort`/`profile` directive) in a Codex `SKILL.md`
body — they are inert and misleading. Such notes existed briefly and were removed (dotfiles
`codex-session/.agents/skills`); do not reintroduce them. This table is the single source of truth
for which profile each skill should be launched with:

| Codex skill             | Profile                     | Who sets it (at launch)                 |
| ----------------------- | --------------------------- | --------------------------------------- |
| gc                      | `quick`                     | caller's `--profile`                    |
| ast-grep                | `quick`                     | caller's `--profile`                    |
| ask                     | `medium`; `quick` via `-f`  | caller's `--profile`; `-f` → `quick`    |
| test-review             | `low`                       | caller's `--profile`                    |
| suckless-patcher        | `low`                       | caller's `--profile`                    |
| refactor-migration-plan | `medium`                    | caller's `--profile`                    |
| review-code-deep        | `medium` (r1) / `low` (r2+) | `review-loop` per round                 |
| implementation-reviewer | `medium` (→ `deep`)         | caller's `--profile`; escalate manually |
| plan-writer             | `medium`                    | `plan-writer-multi` coordinator         |

## Pre-flight: Account Health

Before the first `codex-session` call in a workflow (including the sandbox detection probe), run a
health check to fail fast if no accounts are eligible:

```bash
if ! codex-session account health --format json > "$RUN_DIR/account-health.json" 2>&1; then
  echo "ERROR: no healthy codex-session accounts available"
  cat "$RUN_DIR/account-health.json" >&2
  rm -f "$LOCK_FILE"
  exit 1
fi
```

This runs once per skill invocation, not before every `codex-session exec` call. For skills without
a lock file, omit the `rm -f "$LOCK_FILE"` line. For skills without a `$RUN_DIR`, redirect to
`/dev/null` instead.

The `--format json` flag produces structured output suitable for AI consumption. A non-zero exit
code means no accounts are healthy enough to proceed.

## Environment Compatibility

Codex CLI uses bubblewrap (`bwrap`) for all `--sandbox` modes. Bubblewrap requires
`kernel.unprivileged_userns_clone=1`, which is unavailable in many container environments
(devcontainers, codespaces, Docker without `--privileged`). All sandbox modes
(`--sandbox read-only`, `--sandbox workspace-write`, `--full-auto`) fail with:

```text
bwrap: No permissions to create a new namespace, likely because the kernel does not
allow non-privileged user namespaces.
```

### Sandbox Detection Probe

Before the first Codex call in a workflow, run a lightweight probe to determine whether the native
sandbox works:

```bash
SANDBOX_MODE="native"
if codex-session exec --sandbox read-only --json "echo probe" < /dev/null 2>&1 \
    | grep -q "No permissions to create a new namespace"; then
  SANDBOX_MODE="fallback"
fi
```

### Fallback Patterns

When `SANDBOX_MODE=fallback`, use these alternatives:

**Read-only calls** (stage 1, review rounds): use `-c` config override instead of
`--sandbox read-only`:

```bash
codex-session exec \
  -c 'sandbox_permissions=["disk-full-read-access"]' --json \
  --output-last-message "$RUN_DIR/stage1-plan.txt" \
  "<planning prompt>" \
  < /dev/null > "$RUN_DIR/stage1-events.jsonl"
```

**Write-capable calls** (stage 3 implementation): use `--dangerously-bypass-approvals-and-sandbox`
instead of `--full-auto`. This is the documented Codex approach for externally-sandboxed
environments (devcontainers, CI runners):

```bash
codex-session exec --profile medium \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

**Session resumption** (stage 3 resume, review rounds): `--profile` is an `exec`-level flag, so it
must appear before the `resume` subcommand:

```bash
codex-session exec --profile medium resume "$THREAD_ID" \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

For resumed read-only calls in non-resume-compatible workflows, the existing `-c` config override
pattern works in both native and fallback modes. For resume-compatible workflows, see §Unified
Sandbox for Resume Workflows below.

### Unified Sandbox for Resume Workflows

Workflows that use `exec resume` across stages with different access needs (e.g., read-only planning
then write implementation) must use the same sandbox flags on every call. Use
`--dangerously-bypass-approvals-and-sandbox` for all stages and enforce read-only/write behavior via
prompt orientation blocks (see §Behavioral Orientation below).

This is acceptable because these workflows always run inside a container environment where the
external boundary provides OS-level isolation. The orientation blocks are the primary behavioral
control; the CLI flag merely avoids the backend sandbox-parameter-mismatch rejection on resume.

Planning call (resume-compatible):

```bash
codex-session exec \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage1-plan.txt" \
  "<planning prompt with read-only orientation>" \
  < /dev/null > "$RUN_DIR/stage1-events.jsonl"
```

Implementation call (resuming planning session):

```bash
codex-session exec --profile medium resume "$THREAD_ID" \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt with write orientation>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Rationale: `exec resume` fails with JSON-RPC -32600 ("no rollout found") when sandbox parameters
change between original and resumed calls. See `docs/upstream-codex.md` §F15. GitHub issues:
[#3947](https://github.com/openai/codex/issues/3947),
[#5322](https://github.com/openai/codex/issues/5322),
[#16994](https://github.com/openai/codex/issues/16994),
[#18676](https://github.com/openai/codex/issues/18676),
[#19661](https://github.com/openai/codex/issues/19661),
[#23875](https://github.com/openai/codex/issues/23875).

This pattern applies to: `prex` and any future skill that resumes threads across access mode
boundaries.

## Non-Interactive Plan Call

Use this pattern when Codex should plan without modifying the repo:

```bash
codex-session exec --sandbox read-only --json \
  --output-last-message "$RUN_DIR/stage1-plan.txt" \
  "<planning prompt>" \
  < /dev/null > "$RUN_DIR/stage1-events.jsonl"
```

Contract:

- `--sandbox read-only` enforces the planning boundary.
- `--json` → JSONL events on stdout; `--output-last-message` → final agent message on disk.
- Always redirect stdin from `/dev/null` (`< /dev/null`) to prevent blocking on inherited stdin in
  non-interactive contexts (TUI sessions, background agents).
- Do NOT redirect stderr; it must surface to the Bash tool so Claude can detect Codex errors and
  warnings.

## Non-Interactive Implementation Call

> **Deprecation:** `--full-auto` is deprecated since Codex v0.128.0. The upstream replacement is
> `--sandbox workspace-write`. For resume-compatible workflows, use
> `--dangerously-bypass-approvals-and-sandbox` instead (see §Unified Sandbox for Resume Workflows).

Use this pattern when Codex should implement:

```bash
codex-session exec --profile medium --sandbox workspace-write --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Contract:

- `--sandbox workspace-write` is the current write-capable mode for a fresh `exec` in environments
  where bubblewrap works. In container environments or resume-compatible workflows, use
  `--dangerously-bypass-approvals-and-sandbox` (see §Unified Sandbox for Resume Workflows).
- Implementation is the only stage permitted to mutate the repo.
- To continue a prior planning session, use Session Resumption below instead of a fresh `exec`.

## Session Resumption

Use this pattern when Codex should resume an existing session for implementation:

```bash
codex-session exec --profile medium resume "$THREAD_ID" \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Use this pattern when Codex should resume an existing session for read-only review:

```bash
codex-session exec --profile low resume "$THREAD_ID" \
  --dangerously-bypass-approvals-and-sandbox \
  --json --output-last-message "$RUN_DIR/round-N-review.txt" \
  "<review prompt>" \
  < /dev/null > "$RUN_DIR/round-N-events.jsonl"
```

Contract:

- `exec resume` preserves transcript and thread context across calls.
- All calls (write and read-only) use `--dangerously-bypass-approvals-and-sandbox`. Behavioral
  enforcement comes from the orientation block injected in the prompt.
- Re-validate these patterns when upgrading the `codex` CLI.

### Resume Constraint

`exec resume` fails with JSON-RPC -32600 ("no rollout found") when the sandbox mode changes between
the original session and the resumed call. The Codex backend validates session parameter consistency
and rejects mismatches. See `docs/upstream-codex.md` §F15.

For workflows that resume threads across sandbox mode transitions (e.g., read-only planning → write
implementation), use `--dangerously-bypass-approvals-and-sandbox` uniformly across all stages. This
bypasses bubblewrap entirely and sends no sandbox parameters to the backend.

The old pattern (stage 1 `--sandbox read-only` → stage 3 `--full-auto`) triggers this failure.
`codex-session` thread resolution is not the failing component — the error is server-side parameter
validation. Use one sandbox flag consistently across fresh and resumed calls within the same thread.

## Behavioral Orientation

Every Codex prompt in this workflow, whether fresh or resumed, must begin with an orientation block.
When using the unified sandbox approach (`--dangerously-bypass-approvals-and-sandbox`), these blocks
are the **primary behavioral control** — not merely defense-in-depth.

Read-only orientation:

```text
=== STRICT READ-ONLY MODE ===
You are operating in READ-ONLY mode. This is a hard constraint.
PROHIBITED actions — any of these is a critical violation:
- Creating, modifying, or deleting any file
- Writing to any path on disk
- Running git commands (commit, add, push, reset, checkout, etc.)
- Executing any command that mutates system state
PERMITTED actions:
- Reading files, analyzing code, producing text output
- Running read-only shell commands (cat, grep, find, ls, etc.)
Produce your plan as text output only.
===
```

Write orientation:

```text
=== WRITE MODE ACTIVE ===
The prior READ-ONLY restriction no longer applies. You now have WRITE access.
PERMITTED actions:
- Creating, modifying, and deleting files within the workspace
- Running build/lint/test commands
STILL PROHIBITED:
- Running any git commands (commit, add, push, reset, checkout, etc.)
- Writing outside the workspace directory
Implement the plan below exactly. Report all files changed and any deviations.
===
```

Contract:

- Inject the appropriate orientation block on every Codex call (fresh and resumed).
- Resumed review rounds must restate the read-only orientation.
- These blocks are behavioral controls enforced by the model, not OS-level sandboxing. OS-level
  isolation is provided by the container environment.

## Deep Review

Stage 5 delegates to the `/review-loop` skill — never call `codex review` directly:

- `codex review` does not support `--json` or `--output-last-message`.
- `--uncommitted` combined with a positional `[PROMPT]` errors out.
- `/review-loop` uses `codex-session exec --sandbox read-only` for every round. Each round is an
  independent one-shot invocation (no `exec resume`); round 1 passes `--profile medium`, rounds 2+
  pass `--profile low`.

## Thread ID Extraction

Extract the first thread ID from the JSONL stream with:

```bash
jq -r 'select(.type == "thread.started") | .thread_id' \
  "$RUN_DIR/stage1-events.jsonl" | head -1
```

The same pattern works for implementation events.

- Fresh `exec` calls emit `thread.started`.
- Resumed `exec resume` calls may omit `thread.started`; when absent, keep using the originating
  thread ID.
- Thread IDs are UUID-like, e.g. `019cde13-130c-7e91-ba02-55240d945b93`.

## Last Message Retrieval

Read the final Codex message with:

```bash
cat "$RUN_DIR/stage1-plan.txt"
```

or:

```bash
cat "$RUN_DIR/stage3-impl-report.txt"
```

## Timeout Requirement

Use a Bash-tool timeout of `600000ms` for every Codex call. Planning, implementation, and review can
all exceed the default.

Run every Codex call in the **foreground** — `run_in_background` must be false/omitted. The
`codex-session exec`/`resume` wrappers are synchronous with no internal timeout, so a foreground
Bash call with the `600000ms` budget blocks until Codex exits and lets the caller classify the
result. Never background a Codex `exec`/`resume`: orchestrating skills run inside a headless host
**or as an in-session/forked subagent**, and in a headless host there is no event loop after the
turn ends — backgrounding a long run and ending the turn exits the process and **reaps the detached
Codex**, so files may land but later stages never run and the work is silently lost while the
process still exits `0` (in a subagent, backgrounding likewise breaks the synchronous sequencing the
orchestrator relies on). A Codex stage that cannot finish within the `600000ms` window is a
**planning error** (split the work into smaller rounds), never a reason to background; a genuine
overrun surfaces deterministically as a `timeout-124`/`sigterm` status with partial logs. See
[`orchestration/in-session-vs-headless-delegation.md`](orchestration/in-session-vs-headless-delegation.md)
for why delegated work now runs as in-session foreground subagents (not `claude -p`) and why this
foreground rule holds in every host.

## Skill Run Directories

Skills that create temporary run directories must use the XDG-compliant base path:

```bash
_SKILL_RUNS="${XDG_STATE_HOME:-$HOME/.local/state}/claude-session/skill-runs"
mkdir -p "$_SKILL_RUNS"
RUN_DIR="$_SKILL_RUNS/<skill>-$(date -u +%Y%m%dT%H%M%S)-$$"
mkdir -p "$RUN_DIR"
```

This produces paths like `~/.local/state/claude-session/skill-runs/prex-20260527T200809-12345/`.

Do NOT use `/tmp` for run directories. `/tmp` is excluded by Codex's `workspace-write` sandbox mode
(`sandbox_workspace_write.exclude_slash_tmp`) and may not be shared between host and container.

Lock files follow the same convention:

```bash
LOCK_DIR="${XDG_RUNTIME_DIR:-${XDG_STATE_HOME:-$HOME/.local/state}/claude-session/skill-runs}"
```

New and updated skills must not hardcode `/tmp` for run directories or lock files.

## Safety Rules

- Stages 1 and 2 must keep Codex read-only (enforced via orientation block).
- Stage 3 is the only write-capable stage (enforced via orientation block).
- Stage 5 must go through `/review-loop`, never `codex review` directly.
- Unified sandbox flag matrix (for resume-compatible workflows):
  - fresh read-only → `--dangerously-bypass-approvals-and-sandbox` + strict read-only orientation
  - resumed read-only → `--dangerously-bypass-approvals-and-sandbox` + strict read-only orientation
  - fresh write → `--dangerously-bypass-approvals-and-sandbox` + write orientation
  - resumed write → `--dangerously-bypass-approvals-and-sandbox` + write orientation
- For one-shot workflows that never resume, the native sandbox flags are still valid:
  - fresh read-only → `--sandbox read-only`
  - write → `--sandbox workspace-write`
- `--full-auto` is deprecated since Codex v0.128.0. Do not use it in new code.
- `--approval-policy` and `-a` are NOT supported by `codex-session exec`.
- Account auto-selection is the default. Omit `--account` for quota-aware selection, or pass
  `--account auto` explicitly.
- All `codex-session exec` invocations must include `< /dev/null` to prevent blocking on inherited
  stdin. Without this, Codex prints `Reading additional input from stdin...` and hangs until timeout
  when called from TUI sessions or background agents.
- Each call site passes an explicit `--profile` for its use case (`deep`, `medium`, `low`, `quick`;
  see §Profile Strategy). `--profile` is an `exec`-level flag, so on a resume it goes before the
  `resume` subcommand. Codex v0.134+ has no in-file default-profile selector — the wrapper never
  injects one.
- Codex must never run git commands. All git operations belong to the Claude Code orchestrator.
- Do NOT use `/tmp` for skill run directories or lock files. Use the XDG base path from §Skill Run
  Directories.

## Wrapper Exit Codes

`codex-session` uses sysexits-aligned exit codes. The wrapper never invents non-standard codes.
Canonical exit code list: [`README.md`](https://github.com/gubasso/codex-session#exit-codes); SoT:
`src/error.rs`. The table below adds trigger context for skill authors.

| Code | Sysexits name    | Trigger                                            |
| ---- | ---------------- | -------------------------------------------------- |
| 64   | `EX_USAGE`       | Invalid CLI arguments                              |
| 65   | `EX_DATAERR`     | Quota response parse failure                       |
| 66   | `EX_NOINPUT`     | File not found (IO)                                |
| 69   | `EX_UNAVAILABLE` | Quota fetch failure                                |
| 70   | `EX_SOFTWARE`    | Internal error, child recursion                    |
| 74   | `EX_IOERR`       | IO error, child exec failure, registry/cooldown IO |
| 75   | `EX_TEMPFAIL`    | Auth failure, no eligible account                  |
| 77   | `EX_NOPERM`      | Permission denied (IO)                             |
| 78   | `EX_CONFIG`      | Config error, account not found/already exists     |
| 126  | —                | Child binary not executable                        |
| 127  | —                | Child binary not found                             |

Child exit codes pass through directly when the child exits normally.

## Practical Implications

- Prefer `exec resume` within a workflow to preserve context and reduce token cost.
- Persist JSONL event logs whenever a downstream stage may need the thread ID.
- Treat resumed JSONL streams as possibly missing `thread.started`; fall back to the originating
  thread ID.
- Call `codex-session` directly from Bash; do not introduce wrapper scripts for one-line
  orchestration.
