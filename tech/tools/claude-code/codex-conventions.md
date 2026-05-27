# Codex CLI Conventions

This file captures the verified Codex CLI conventions used by the `prex` workflow. Reuse these
patterns for future Claude-side orchestration work.

## Version Baseline

- **SoT:** `codex-session --version` (prints wrapper version, child binary path + version, active
  account).
- Default stock Codex profile is `deep` (gpt-5.5, high effort). Execution/review calls override with
  `--profile fast` (gpt-5.4-mini, medium effort). **SoT:**
  `~/.config/codex-session/settings/base.toml`.

## Wrapper: `codex-session`

Every Codex invocation in this document and in skill files uses `codex-session`, which composes a
profile, resolves the active account, sets `CODEX_HOME` to the per-account per-group session
directory, and passes through to the stock `codex` binary.

**Install:** `codex-session` must be on `PATH`. Verify with `codex-session --version`.

**Per-call lifecycle:** the wrapper resolves account + group-id, then sets
`CODEX_HOME=<state>/accounts/<account>/groups/<group-id>/`. Group-id resolution follows a 5-step
chain: `--group` flag > `CODEX_SESSION_GROUP` env > stable TTY id > PPID+starttime composite >
warned `pid-N` fallback. On resume, the wrapper restores the original group-id from the thread
index, so `exec resume <ID>` works across terminals and PIDs. The `pid-N` fallback emits a stderr
warning because the derived group is ephemeral and will differ on the next invocation.

**Account resolution:** `--account <name>` flag > `CODEX_SESSION_ACCOUNT` env > LRU pointer (from
`account use`, stored in `state/last-account`) > `config.account.pinned` > `NoneResolved` error.
There is no implicit `"default"` fallback. `--account auto` triggers the R3 quota-aware selector
(non-interactive). See `docs/auth-gate-spec.md` §3.2 for the full specification. All skill and
workflow invocations must pass `--account auto` so account selection is always quota-aware.

**Auth:** `auth.json` lives per-account at `<state>/accounts/<account>/auth.json` and is owned by
the wrapper. Codex writes refresh rotations in place. No write-back to `~/.codex/`.

**Wrapper-owned verbs:** `version`, `completion`, `config status`,
`config-recipe list|show|compose`, `doctor`, `account add|list|current|use|remove|refresh`,
`account quota`, `account cooldown show|clear`.

**Wrapper-owned global flags:** `--group`, `--account`, `--max-retries`, `--config-recipe`,
`--config`, `--format`, `--verbose`/`--quiet`/`--silent`, `--log-stderr`, `--log-format`.

**Argv pattern:** `codex-session --account auto exec ...` and
`codex-session --account auto exec resume <thread-id> ...`. Planning calls omit `--profile` and
inherit the `deep` default. Execution and review calls pass `--profile fast` explicitly:

```text
codex-session --account auto exec --profile fast ...
codex-session --account auto exec resume <thread-id> --profile fast ...
```

## Profile Strategy

Two stock Codex profiles are defined in `base.toml`:

- **`deep`** (default) — no model override (inherits current catalog default), `high` effort. Used
  for planning and new-thread reasoning tasks. Calls omit `--profile`.
- **`fast`** — `gpt-5.4-mini`, `medium` effort. Used for execution (implementation resume, code
  review rounds). Calls pass `--profile fast` after `exec` or `exec resume`.

The wrapper renamed its own profile flag to `--config-recipe` (commit 3117d8e), so `--profile`
passes through to stock Codex for selecting `[profiles.*]` tables. `ping` remains a
health-probe-only profile.

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
if codex-session --account auto exec --sandbox read-only --json "echo probe" < /dev/null 2>&1 \
    | grep -q "No permissions to create a new namespace"; then
  SANDBOX_MODE="fallback"
fi
```

### Fallback Patterns

When `SANDBOX_MODE=fallback`, use these alternatives:

**Read-only calls** (stage 1, review rounds): use `-c` config override instead of
`--sandbox read-only`:

```bash
codex-session --account auto exec \
  -c 'sandbox_permissions=["disk-full-read-access"]' --json \
  --output-last-message "$RUN_DIR/stage1-plan.txt" \
  "<planning prompt>" \
  < /dev/null > "$RUN_DIR/stage1-events.jsonl"
```

**Write-capable calls** (stage 3 implementation): use `--dangerously-bypass-approvals-and-sandbox`
instead of `--full-auto`. This is the documented Codex approach for externally-sandboxed
environments (devcontainers, CI runners):

```bash
codex-session --account auto exec --profile fast \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

**Session resumption** (stage 3 resume, review rounds): the same flag applies to `exec resume`:

```bash
codex-session --account auto exec resume "$THREAD_ID" --profile fast \
  --dangerously-bypass-approvals-and-sandbox --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

For resumed read-only calls, the existing `-c` config override pattern works in both native and
fallback modes — no change needed.

## Non-Interactive Plan Call

Use this pattern when Codex should plan without modifying the repo:

```bash
codex-session --account auto exec --sandbox read-only --json \
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

Use this pattern when Codex should implement:

```bash
codex-session --account auto exec --profile fast --full-auto --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Contract:

- `--full-auto` is the v1 implementation default and the only write-capable mode for a fresh `exec`.
- Implementation is the only stage permitted to mutate the repo.
- To continue a prior planning session, use Session Resumption below instead of a fresh `exec`.

## Session Resumption

Use this pattern when Codex should resume an existing session for implementation:

```bash
codex-session --account auto exec resume "$THREAD_ID" --profile fast --full-auto --json \
  --output-last-message "$RUN_DIR/stage3-impl-report.txt" \
  "<implementation prompt>" \
  < /dev/null > "$RUN_DIR/stage3-events.jsonl"
```

Use this pattern when Codex should resume an existing session for read-only review:

```bash
codex-session --account auto exec resume "$THREAD_ID" --profile fast \
  -c 'sandbox_permissions=["disk-full-read-access"]' \
  --json --output-last-message "$RUN_DIR/round-N-review.txt" \
  "<review prompt>" \
  < /dev/null > "$RUN_DIR/round-N-events.jsonl"
```

Contract:

- `exec resume` preserves transcript and thread context across calls.
- `--sandbox read-only` is NOT accepted by `exec resume`; for read-only resumed calls use
  `-c 'sandbox_permissions=["disk-full-read-access"]'`.
- `--full-auto` is the write-capable mode for resumed implementation.
- Re-validate these patterns when upgrading the `codex` CLI.

## Behavioral Orientation

Every Codex prompt in this workflow, whether fresh or resumed, must begin with an orientation block.

Read-only orientation:

```text
You are in READ-ONLY mode. Do not create, modify, or delete any files. Only read and analyze. Do not run any git commands.
```

Write orientation:

```text
The prior READ-ONLY restriction no longer applies. You now have WRITE access. Implement the plan below. Report all files changed and any deviations. Do not run any git commands.
```

Contract:

- Inject the orientation block on every Codex call (fresh and resumed), even when the CLI sandbox is
  enforced. It is defense-in-depth.
- Resumed review rounds must restate the read-only orientation.

## Deep Review

Stage 5 delegates to the `/review-loop` skill — never call `codex review` directly:

- `codex review` does not support `--json` or `--output-last-message`.
- `--uncommitted` combined with a positional `[PROMPT]` errors out.
- `/review-loop` uses `codex-session --account auto exec --sandbox read-only` for round 1, then
  `codex-session --account auto exec resume` with `-c` config-enforced read-only for later rounds.

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

## Safety Rules

- Stages 1 and 2 must keep Codex read-only.
- Stage 3 is the only write-capable stage; use `--full-auto` (or
  `--dangerously-bypass-approvals-and-sandbox` in fallback mode) on either a fresh `exec` or an
  `exec resume`.
- Stage 5 must go through `/review-loop`, never `codex review` directly.
- Native sandbox flag matrix:
  - fresh read-only → `--sandbox read-only`
  - resumed read-only → `-c 'sandbox_permissions=["disk-full-read-access"]'`
  - write → `--full-auto`
- Fallback sandbox flag matrix (`SANDBOX_MODE=fallback`):
  - read-only (fresh or resumed) → `-c 'sandbox_permissions=["disk-full-read-access"]'`
  - write → `--dangerously-bypass-approvals-and-sandbox`
- `--approval-policy` and `-a` are NOT supported by `codex-session --account auto exec`.
- All invocations must pass `--account auto` for quota-aware account selection.
- All `codex-session exec` invocations must include `< /dev/null` to prevent blocking on inherited
  stdin. Without this, Codex prints `Reading additional input from stdin...` and hangs until timeout
  when called from TUI sessions or background agents.
- Planning and new-thread calls inherit the default `deep` profile (no `--profile` flag). Execution
  and review calls must pass `--profile fast` after `exec` or `exec resume`.
- Codex must never run git commands. All git operations belong to the Claude Code orchestrator.

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
