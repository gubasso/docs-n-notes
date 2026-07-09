# 06 — Preflight & Health Checks

> Prerequisite: [README](./README.md) for the vocabulary. This chapter covers two halves of one
> idea: a first-class `doctor` command that aggregates **every** environment prerequisite, and
> **per-subcommand preflight guards** that reuse those same checks to fail fast before doing work.
>
> Closely related: [00 — Architecture](./00-architecture.md) for the `AppContext` the checks read
> from; [02 — Error Messages](./02-error-messages.md) for stable `err.kind` keys and exit codes;
> [05 — Designing for LLM coding agents](./05-designing-for-llm-agents.md) §2.8 for `doctor` as a
> machine surface; [99 — Checklist](./99-checklist.md) for the pre-ship rubric.

Every non-trivial CLI has prerequisites: a device or dependency present, a config readable, an auth
token valid, a service reachable. Two failure modes are common and both are bad. One: the tool
assumes the prerequisite, starts work, and dies halfway with an opaque error (or worse, a
half-applied mutation). Two: each command re-implements its own ad-hoc checks that drift from each
other and from the docs. The fix is one catalog of checks with **three call sites**: `doctor` runs
the whole catalog, each subcommand fail-fast-guards the subset it needs, and setup verbs reuse the
same checks.

## Contents

1. [TL;DR](#tldr)
2. [Per-subcommand preflight guards](#1-per-subcommand-preflight-guards)
3. [The doctor command as aggregator](#2-the-doctor-command-as-aggregator)
4. [Hard vs soft prerequisites](#3-hard-vs-soft-prerequisites)
5. [One source of truth](#4-one-source-of-truth)
6. [Exit codes & remediation](#5-exit-codes--remediation)
7. [Worked example: `pigeon`](#6-worked-example-pigeon)
8. [Checklist](#checklist)
9. [See also](#see-also)

## TL;DR

- **Every subcommand validates its prerequisites at entry and fails fast — before any side effect.**
  A missing prerequisite must never leave a half-applied mutation or surface as a late, opaque
  error.
- **One `doctor` command aggregates _all_ environment checks.** It is first-class, not an
  afterthought; it must not limit itself to probing one thing.
- **One probe set, three call sites.** `doctor` (whole catalog), per-command preflight guards (the
  subset that command depends on), and `init`/setup (reuse the checks). Never a parallel, ad-hoc
  check that can drift from the catalog.
- **Every check has a stable ID.** IDs double as `err.kind` keys ([02](./02-error-messages.md)) and
  as doc anchors, so automation and remediation can rely on them.
- **Hard prerequisites block (fail fast, non-zero exit); soft ones warn and fall back.** Classify
  each one explicitly; never let a soft check gate, never let a hard check pass silently.
- **A guard emits the check's remediation verbatim** — the same actionable string `doctor` would
  print. A generic "unavailable" is a bug.

## 1. Per-subcommand preflight guards

A **preflight guard** runs a command's hard prerequisites at command entry and refuses _up front_ if
any is unmet — before the first network call, subprocess, or state mutation. This is distinct from
an error mapped out of a failure deep in execution: the guard's whole job is to turn a would-be
late, half-applied failure into an immediate, clean refusal.

Bad — assume, then die deep in the work:

```text
$ pigeon dispatch --to roost-42 --body "stand by"
dispatching... connecting to registry... resolving roost-42...
Error: SendError: broken pipe          # auth token was expired the whole time
# a partial send may already have happened; the user has no idea what to fix
```

Good — guard first, refuse before any effect:

```text
$ pigeon dispatch --to roost-42 --body "stand by"
Error: credentials — auth token expired 3 days ago (err.kind: creds-expired)
Fix: pigeon auth login        # then re-run
# nothing was sent; exit code marks an unmet prerequisite
```

The rule: **a command that genuinely depends on a readiness condition treats it as a hard
prerequisite and verifies it at entry.** Read-only or inert commands (`status`, `version`, `help`,
`doctor` itself, list/show verbs) have no such prerequisites and must **not** gate — gating them is
its own bug (it makes the tool unusable exactly when you want to diagnose it).

Keep the guard cheap. It runs on every invocation of a hot command, so it should verify _presence
and validity_, not do the expensive work itself (probe the token's expiry field; don't make a
round-trip to mint a new one). When a check is genuinely expensive, prefer a cached result with a
short TTL, or make it a `doctor`-only check and let the command surface the failure lazily.

## 2. The doctor command as aggregator

`doctor` is the single place a user or agent runs to answer "is my environment ready, and if not,
exactly what do I fix?" It MUST check **all** program requirements — dependencies, permissions,
config and schema validity, credentials, connectivity, state consistency, known-bad conditions — and
MUST NOT limit itself to probing a single dependency or path. Each finding names the requirement
precisely and gives a concrete remediation. (See [05 §2.8](./05-designing-for-llm-agents.md) for why
agents lean on this so heavily.)

Give `doctor` a `--scope` selector (host, config, auth, network, …) so it can run a category in
isolation, and `--json` so agents and CI consume it structurally. Group the human report by category
with a per-check status marker and a trailing summary.

## 3. Hard vs soft prerequisites

Classify every check as **hard** or **soft**, and make the class part of the catalog:

- **Hard** — the command cannot succeed without it. The guard **blocks**: refuse with a non-zero
  exit and remediation. Example: no auth token → `dispatch` cannot send.
- **Soft** — degraded but workable. The command **warns and proceeds on a documented fallback**,
  never blocks. Example: a fast local cache is unavailable → fall back to a slower path; a preferred
  transport is absent → use the compatible one.

The failure of classification is the common bug: a soft check wired as a hard gate blocks users for
no reason; a hard requirement left as a warning lets the command march into a guaranteed late
failure. In the catalog, a check's **severity** (fail vs warning) _is_ its class.

## 4. One source of truth

`doctor`, the per-command guards, and `init`/setup are three call sites over **one** set of probe
functions, addressed by stable check ID. Do not re-implement a command's checks independently — that
is how the guard and the diagnostics drift until `doctor` says "OK" and the command still fails.

Concretely: write each check as a small probe returning a structured result (`id`, `status`,
`message`, `remediation`). `doctor` runs the whole list; a command's guard runs a named subset and
maps any hard failure to its exit code + remediation; `init` runs the setup-relevant subset and
reports afterward. Adding a new prerequisite is then a single edit — a new probe in the catalog —
and all three call sites pick it up.

```text
           ┌────────────────────────┐
           │  check catalog (probes) │   id · status · message · remediation
           └───────────┬────────────┘
     ┌─────────────────┼──────────────────┐
     ▼                 ▼                  ▼
doctor (all)   command guard (subset)   init (setup subset)
```

## 5. Exit codes & remediation

A guard's refusal must carry a **specific, stable exit code**, not a generic `1`. Reuse your error
taxonomy from [02 — Error Messages](./02-error-messages.md): BSD sysexits give you `EX_CONFIG` (78)
for bad config, `EX_NOPERM` (77) for permissions, `EX_UNAVAILABLE` (69) for a missing dependency or
unreachable service. Many CLIs instead define a small stable numeric taxonomy and reserve one code
for "unmet prerequisite" (e.g. podbox reserves exit `3` for an unmet host/runtime requirement).
Either way: the code is stable, documented, and the same whether the failure is caught by `doctor`
or by a command's preflight guard.

Every failing check prints **what** is wrong, **where**, and the **exact command** to fix it — never
a bare "unavailable". The remediation string lives with the probe, so `doctor` and the guard emit it
identically.

## 6. Worked example: `pigeon`

`pigeon doctor` runs the whole catalog:

```text
$ pigeon doctor
config         OK   /home/user/.config/pigeon/config.toml
credentials    OK   token expires in 14 days
roost registry OK   42 active roosts reachable
local schema   WARN v3 (CLI expects v4). Run: pigeon migrate      # soft: works, degraded
weather api    FAIL could not resolve api.winds.example.com       # hard for `forecast`

Next:
  pigeon migrate --from v3 --to v4
  Check network: curl -v https://api.winds.example.com/ping
```

Each command guards the **subset** it depends on, reusing those exact probes:

| Command                          | Hard (block)                              | Soft (warn + fall back)             |
| -------------------------------- | ----------------------------------------- | ----------------------------------- |
| `pigeon dispatch`                | `config`, `credentials`, `roost registry` | `local schema` (migrate later)      |
| `pigeon forecast`                | `config`, `weather api`                   | —                                   |
| `pigeon flock list`              | `config`                                  | `roost registry` (show cached list) |
| `pigeon status`, `pigeon doctor` | _(none — never gate)_                     | —                                   |

So `pigeon dispatch` refuses instantly when the token is expired (hard), but runs fine while the
schema is a stale v3 (soft — it warns and migrates on its own schedule). `pigeon forecast` refuses
when the weather API is unreachable, which for `dispatch` was never a prerequisite at all. One
catalog, per-command subsets, no drift.

## Checklist

- [ ] A first-class `doctor` (or `health`/`diagnose`) checks **all** prerequisites, not one path.
- [ ] `doctor` supports `--scope` and `--json`; the human report is grouped with a summary.
- [ ] Every check has a **stable ID** that doubles as an `err.kind` key and a doc anchor.
- [ ] Each check is classified **hard** (blocks) or **soft** (warns + fallback) in the catalog.
- [ ] Each subcommand runs its hard-prerequisite subset **at entry** and refuses before any side
      effect.
- [ ] Read-only/inert commands (`status`, `version`, `help`, `doctor`, list/show) do **not** gate.
- [ ] Guards, `doctor`, and `init` share **one** probe set — no independent per-command checks.
- [ ] A refusal carries a **specific stable exit code** and the check's **remediation string**
      verbatim.

## See also

- [02 — Error Messages](./02-error-messages.md) — stable `err.kind` keys and BSD sysexits the guards
  reuse.
- [05 — Designing for LLM coding agents](./05-designing-for-llm-agents.md) §2.8 — `doctor`/`init` as
  machine surfaces agents run first.
- [00 — Architecture](./00-architecture.md) — the `AppContext` the checks read from.
- [99 — Checklist](./99-checklist.md) — the one-page pre-ship rubric.
