# Multi-Repo Commit Contract

How an executor commits work that spans more than one git repository. The rule: **a caller that runs
or coordinates changes and then commits must commit the work in _every_ repo it touched, by
default** — the source repo plus any satellite/target repo (e.g. a project being extracted into) or
SoT docs repo (e.g. DocsNNotes). It asks the user only when something looks off.

The deterministic mechanics live in `agent-helper`; the `gc` skill (Claude and Codex) and callers
like `plan-queue-runner` stay thin orchestrators. This file defines the **contracts and shapes**.

## Why

`git rev-parse --show-toplevel` resolves a single repo from the current directory. A commit step
that runs only there silently drops work that landed in another repo — and can report
`COMMIT_OK <sha>` truthfully while the real artifacts sit uncommitted elsewhere. The contract below
makes "committed" mean "every touched repo committed."

## `agent-helper gc-plan` — partition + safety scan

Read-only. Resolves every session path to its owning git repo and reports what to commit per repo
plus any surprises.

```bash
agent-helper gc-plan --session-files <file> [--repo <dir>]... [--repo-set <file>] --json
```

Output:

```json
{
  "ok": true,
  "repos": [ {"root": "/abs/repo", "paths": ["a"], "extra_dirty": ["b"]} ],
  "undeclared_dirty": [ {"root": "/abs/other", "paths": ["x"]} ],
  "declared_no_change": ["/abs/declared-clean"],
  "escapes": ["/abs/path-in-no-repo"],
  "invalid_repos": ["/not/a/repo"],
  "surprises": ["undeclared-repo:/abs/other"]
}
```

- `repos[]` — the repos to commit, in deterministic order (the cwd repo first, then
  declared/explicit order, then any freeform extras in first-appearance order). `paths` are
  repo-relative; `extra_dirty` are other dirty paths in that repo not in the session list (the
  per-repo generalization of the "mixed changes → ask" rule).
- `escapes[]` — session paths in no git repo. Sets `ok:false` (a hard input error).
- `surprises[]` — non-empty means the skill must STOP and ask the user.

### Declared set + safety scan

- **Freeform** (no `--repo`/`--repo-set`): the declared set is auto-derived from the session files'
  owning repos. Every touched repo is accepted and committed by default. This is the "edited code +
  a docs repo, then `/gc`" case — both commit, no prompt.
- **Allowlist** (`--repo`/`--repo-set` given): the declared set is those roots plus the cwd repo. A
  session path in a repo outside the set becomes `undeclared_dirty` + a surprise. This is the
  orchestrated case (e.g. `plan-queue-runner` forwarding its declared satellites): an unexpected
  repo is flagged rather than silently committed.

Detection is deterministic and in the helper; the ask/decision stays prose in the skill.

## `--repo-root` on gc-stage / gc-commit / gc-push

Each accepts an optional `--repo-root <dir>` that targets a specific repo (via `git -C`) without
`cd`. Omitted ⇒ the current directory's repo, byte-identical to the historical single-repo behavior.
The skill loops `gc-plan`'s `repos[]` and runs the stage → commit → (push) cycle once per repo with
the matching `--repo-root`; per-repo commit-message drafting stays prose judgment.

## COMMIT_* result-line grammar

Single repo (unchanged): `COMMIT_OK <sha>` / `COMMIT_PUSH_OK <sha>` / `COMMIT_FAILED <reason>` /
`COMMIT_PUSH_FAILED <reason>`.

Multi-repo: one line per committed repo with a free-form `repo=<root>` suffix, e.g.
`COMMIT_OK <sha> repo=/abs/repo`. Produced via `agent-helper msg ok commit "$SHA repo=$ROOT"` (the
suffix rides the free-form detail — no `msg` change). The skill emits these as the trailing block of
its reply, nothing after.

## Parse contract (`plan-queue-runner-parse-commit`)

Scans every `COMMIT_*` line:

- One line, no `repo=` suffix ⇒ legacy single-repo form ⇒ `COMMIT_SHA=<sha>` (backward compatible).
- Multi-repo ⇒ one `COMMIT_SHA=<sha> repo=<root>` per repo (or `--json`
  `{"ok":true,"commits":[{"repo","sha","line"}]}`).
- **Any** `COMMIT_*_FAILED` line ⇒ fail closed (exit 1), surfacing every failed repo, even alongside
  successful ones. Git has no cross-repo rollback, so a partial commit is reported as-is and treated
  as a hard fail by the runner.
- No `COMMIT_*` line ⇒ fail.

## QUEUE.yaml `repos:` field (plan-queue-runner)

A plan whose rounds write into satellite repos declares them in an **optional top-level `repos:`
list** (sibling to `rounds:`), each an absolute path:

```yaml
repos:
  - /abs/path/to/satellite
rounds:
  - item: ...
```

- Optional; absent ⇒ single-repo (historical behavior).
- `repos:` must come **before** `rounds:` (the append target must stay last for append-only
  splices).
- The clean-tree guard covers `REPO_ROOT` + every declared satellite; the commit step runs
  `/gc -y -a --repo <sat>...` so each satellite's artifacts are committed alongside the `QUEUE.yaml`
  status flip in `REPO_ROOT`.
- `plan-queue-runner-setup` persists the list to `ctx.env` as newline-joined `REPOS`.

## Caller responsibilities (the general rule)

Any executor/caller that coordinates changes across repos and calls `/gc`:

1. Hands `/gc` the full session-file set (absolute paths may span repos) and, when it has an
   explicit expectation, the declared satellite repos via `--repo`.
2. Commits every touched repo by default; deviates only on a `gc-plan` surprise, then asks the user.
3. Treats any per-repo `*_FAILED` as a hard fail.

Today only `plan-queue-runner` commits through `/gc`. `prex` and `review-loop` never commit (Codex
runs no git; the parent owns git ops), so they inherit nothing to change beyond this contract's
existence. New orchestrators that commit must follow the three points above.
