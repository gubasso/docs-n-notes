# Codex CLI Conventions

This file captures the verified Codex CLI conventions used by the `prex` workflow. Reuse these
patterns for future Claude-side orchestration work.

## Version Baseline

- **SoT:** `codex-session --version` (prints wrapper version, child binary path + version, active
  account).
- Stock skill workflow uses base config by default: planning/new-thread calls omit `--profile`, so
  codex uses only the base `config.toml` (no profile overlay). Profile files are available via
  explicit `--profile <name>` and none is auto-activated. Execution/review calls pass
  `--profile fast` (gpt-5.4-mini, medium effort). Codex v0.134+ has no in-file default-profile
  selector. **SoT:** `~/.config/codex-session/profiles/<name>.config.toml` (one file per profile,
  bare top-level keys, no `[profiles.<name>]` header).

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

**Auth:** `auth.json` lives per-account at `<state>/accounts/<account>/auth.json` and is owned by
the wrapper. Codex writes refresh rotations in place. No write-back to the user's default codex
home.

**Wrapper-owned verbs:** `version`, `completion`, `config status`,
`config-recipe list|show|compose`, `doctor`, `account add|list|current|remove|refresh`,
`account quota`, `account cooldown show|clear`.

**Wrapper-owned global flags:** `--group`, `--account`, `--max-retries`, `--config-recipe`,
`--config`, `--format`, `--verbose`/`--quiet`/`--silent`, `--log-stderr`, `--log-format`.

**Argv pattern:** `codex-session exec ...` and
`codex-session exec [--profile fast] resume <thread-id> ...`. The no-arg account form is the
quota-aware default; `--account auto` is the explicit alias, and `--account <name>` pins one
account. Planning/new-thread calls omit `--profile`, so codex uses only the base `config.toml` (no
profile overlay). Execution and review calls pass `--profile fast` on `exec` (before the `resume`
subcommand if resuming, since `--profile` is an `exec`-level flag). codex-session itself never
injects `--profile`:

```text
codex-session exec --profile fast ...
codex-session exec --profile fast resume <thread-id> ...
```

## Profile Strategy

Profile overrides live as separate files under `~/.config/codex-session/profiles/<name>.config.toml`
(codex v0.134+ contract). Each file contains bare top-level keys, no `[profiles.<name>]` header.
codex-session emits these 1:1 as siblings of the base `config.toml` in the session's `$CODEX_HOME/`.

Stock profiles used by skills:

- **`deep`** — high reasoning effort, full sandbox. Available for explicit planning/new-thread runs
  that pass `--profile deep`; omitting `--profile` uses base config only. codex itself no longer
  supports an in-file default selector, and codex-session does not auto-activate any profile.
- **`fast`** — `gpt-5.4-mini`, `medium` effort. Used for execution (implementation resume, code
  review rounds). Calls pass `--profile fast` on `exec` (before the `resume` subcommand if
  resuming).
- **`ping`** — health-probe-only profile, used internally by `account health`.

The wrapper's own composability lever is `--config-recipe` (commit 3117d8e). The `--profile` flag
passes through to stock codex unchanged. codex-session never injects `--profile` for user-facing
pass-through calls; wrapper-owned health probes (e.g. the heartbeat check in `account health`) may
pass `--profile ping` internally.

References: `docs/upstream-codex.md` §F6b–§F6c (codex-session repo);
<https://developers.openai.com/codex/config-advanced#profiles>.

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
codex-session exec --profile fast \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

**Session resumption** (stage 3 resume, review rounds): `--profile` is an `exec`-level flag, so it
must appear before the `resume` subcommand:

```bash
codex-session exec --profile fast resume "$THREAD_ID" \
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
codex-session exec --profile fast resume "$THREAD_ID" \
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
codex-session exec --profile fast --sandbox workspace-write --json \
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
codex-session exec --profile fast resume "$THREAD_ID" \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Use this pattern when Codex should resume an existing session for read-only review:

```bash
codex-session exec --profile fast resume "$THREAD_ID" \
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
  independent one-shot invocation (no `exec resume`); round 1 uses only the base `config.toml` (no
  profile overlay), rounds 2+ pass `--profile fast`.

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
- Planning and new-thread calls omit `--profile`, so codex uses only the base `config.toml` (no
  profile overlay). Execution and review calls must pass `--profile fast` on `exec` (before the
  `resume` subcommand if resuming). Codex v0.134+ has no in-file default-profile selector — the
  wrapper never injects one.
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
