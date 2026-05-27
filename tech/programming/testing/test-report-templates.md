# Output Templates

Skeletons for the three artifacts the `test-review` skill produces in `.test-review/` and the codex
hand-off prompt the skill prints at the end.

## `MANIFEST.yaml`

Machine-readable state. Written in Phase 0, updated in Phase 2 (post-approval) and Phase 3
(post-plan).

```yaml
# .test-review/MANIFEST.yaml
schema: 1
generated-at: "2026-05-19T18:00:00Z"          # UTC ISO 8601
generated-by: "claude:test-review:1.0"

round: 1                                       # increments on re-runs
phase: 3-complete                              # 0-init | 1-lint | 2-findings | 3-plan-complete | 4-implementing | 5-done

principles:
  path: "/home/gu/Projects/docs-n-notes/tech/programming/cli-design/08-testing-and-quality/testing-strategy.md"
  resolution-source: "probe"                   # flag | env | docs-notes-repo | probe | embedded-fallback
  sha256: "abc123…"                            # to detect drift between rounds

discovery:
  scope-glob: null                             # value of --scope or null
  include-e2e: false
  languages: ["python", "bash"]
  test-files-count: 47
  test-cases-count: 312                        # if cheap to estimate

findings:
  total: 23
  by-severity: { critical: 5, high: 12, info: 6 }
  by-rule: { TR-001: 3, TR-002: 2, TR-010: 4, TR-016: 8, TR-022: 6 }
  top-files:
    - { path: "tests/test_api_client.py", critical: 3, high: 2 }
    - { path: "tests/test_widget.py",    critical: 1, high: 5 }

plan:
  tasks-total: 18                              # findings can collapse into one task each, or merge
  tasks-by-effort: { S: 11, M: 5, L: 2 }
  codex-handoff-prompt: |
    <see "Codex hand-off prompt" template below>

approvals:
  phase-2:
    at: "2026-05-19T18:12:34Z"
    response: "approve"
    excluded-findings: []
    deferred-findings: []

implementation-log: []                          # codex twin appends here
```

## `FINDINGS.md`

Human-readable report, grouped by file then severity. Written in Phase 2.

````markdown
# Test Review — Findings

Generated: 2026-05-19T18:00:00Z Round: 1 Principles:
`/home/gu/.../08-testing-and-quality/testing-strategy.md` (sha256: abc123…) Scope: 47 test files,
312 test cases, languages: python, bash Excluded: e2e tier (use `--include-e2e` to audit it).

## Summary

| Severity    | Count  |
| ----------- | ------ |
| ⛔ critical | 5      |
| ⚠️ high      | 12     |
| ℹ️ info      | 6      |
| **total**   | **23** |

Top three files by critical findings:

1. `tests/test_api_client.py` — 3 critical, 2 high.
2. `tests/test_widget.py` — 1 critical, 5 high.
3. `tests/test_renderer.py` — 1 critical, 1 high.

## Findings

### `tests/test_api_client.py`

#### F-001 — ⛔ critical — TR-002 mock is the only subject

**Lines:** 42-58

**What:**

```python
def test_fetch_data():
    m = MagicMock()
    m.get.return_value.json.return_value = {"ok": True}
    with patch("myapp.client.requests", m):
        fetch_data()
    m.get.assert_called_once_with("https://api.example.com/data")
```

The test fully stubs `requests` and only asserts on the stub's call shape. `fetch_data`'s actual
return value is never checked.

**Why it matters:** principle 4 — _Don't test third-party libraries_
(`08-testing-and-quality/testing-strategy.md:10`). This test would pass even if `fetch_data`
returned the wrong value or raised an exception after the call.

**Fix:** replace the `MagicMock(requests)` with a recording HTTP fake (e.g. `respx` or `vcrpy`).
Assert on `fetch_data`'s return value, not on the stub's calls. See
`tool-matrix.md:#tr-001--tr-002--tr-005-widespread`.

---

#### F-002 — ⛔ critical — TR-001 assertion subject is a non-project import

**Lines:** 71-74

**What:**

```python
def test_serializes_response():
    response_dict = {"id": 1, "name": "widget"}
    assert json.dumps(response_dict) == '{"id": 1, "name": "widget"}'
```

The assertion's subject is `json.dumps` — a symbol from the stdlib, not from the project.

**Fix:** delete (this test verifies the standard library) or replace with a test of the project's
`ResponseSerializer`.

**Principle:** `08-testing-and-quality/testing-strategy.md:10`.

---

[…more findings…]

### `tests/test_widget.py`

[…]
````

## `REFACTOR_PLAN.md`

Per-task specification consumed by the codex twin. Plan only; no code. Written in Phase 3 after user
approval.

````markdown
# Test Review — Refactor Plan

Generated: 2026-05-19T18:15:00Z Round: 1 Principles:
`/home/gu/.../08-testing-and-quality/testing-strategy.md` (sha256: abc123…) Findings approved: 21 of
23 (2 deferred; see MANIFEST.yaml) Tasks: 18 (S: 11 · M: 5 · L: 2)

## Execution order

Tasks are grouped by file, then by severity (critical first), then by smallest diff first inside
each severity tier. The codex twin should batch by file (≤5 tasks per batch) and run the project
test suite after each batch.

## Tasks

### T-01-001 — Replace requests mock with respx fake in `test_fetch_data`

- **File:** `tests/test_api_client.py`
- **Lines:** 42-58
- **Severity:** ⛔ critical
- **Source finding:** F-001 (TR-002)
- **Principle:** `08-testing-and-quality/testing-strategy.md:10` (Principle 4)
- **Effort:** M
- **Change spec:**
  1. Replace the `MagicMock(requests)` setup with `respx.mock(base_url="https://api.example.com")`.
  2. Register a route at `/data` returning the expected JSON body.
  3. Replace the `m.get.assert_called_once_with(...)` assertion with
     `assert fetch_data() == Widget(...)` — assert on the return value, not the recorded call.
  4. Add `respx` to test dependencies if absent (do not auto-install; surface in the Suggestions
     section instead).
- **Rollback:** restore the original `tests/test_api_client.py` from git.
- **Flags:** `requires-user-confirm: false`, `coverage-risk: false`, `security-sensitive: false`.

---

### T-01-002 — Delete `test_serializes_response`

- **File:** `tests/test_api_client.py`
- **Lines:** 71-74
- **Severity:** ⛔ critical
- **Source finding:** F-002 (TR-001)
- **Principle:** `08-testing-and-quality/testing-strategy.md:10`
- **Effort:** S
- **Change spec:** delete the test. It verifies the standard library's `json.dumps`; nothing about
  the project's behavior is checked.
- **Rollback:** restore from git.
- **Flags:** `requires-user-confirm: true` (deletion), `coverage-risk: true`.

---

[…more tasks…]

## Suggestions (opt-in, never auto-applied)

The audit detected patterns that would be cheaper to prevent than to lint repeatedly. None of these
are applied automatically — paste into the project at your discretion.

### Add `respx` to test dependencies

```toml
# pyproject.toml
[project.optional-dependencies]
test = [
    "pytest>=8",
    "pytest-xdist",
    "respx>=0.21",                # NEW — for HTTP fakes
]
```

### Wire a pre-commit hook for unit tests

```yaml
# .pre-commit-config.yaml
- repo: local
  hooks:
    - id: pytest-unit
      name: pytest (unit)
      entry: pytest
      language: system
      args: [tests/unit, -x, -q, -n, auto]
      types: [python]
      pass_filenames: false
      stages: [pre-commit]
```

### Add a nightly mutation-testing workflow

[…see tool-matrix.md for the GitHub Actions snippet…]

## Codex hand-off

Paste the prompt below into a Codex session to execute this plan.

```text
You are running the codex `test-review` skill in implementation mode.

Plan file:     .test-review/REFACTOR_PLAN.md
Manifest:      .test-review/MANIFEST.yaml
Principles:    <resolved path from MANIFEST.yaml>

Read the plan top-to-bottom before touching any file. Execute tasks
T-01-001 through T-01-018 in the order listed. After each batch of 5,
run the project test suite (`make test` or equivalent). Abort the batch
on test failure; do not advance to the next batch until tests are green.

For any task flagged `requires-user-confirm: true`, stop and request
approval before applying. For `security-sensitive: true`, require an
explicit human gate. Never auto-update snapshot baselines.

When all tasks are complete (or aborted), emit
.test-review/POST_REFACTOR_REPORT.md per the codex skill's template.
```

## Re-run

To re-run this audit after the refactor (round 2):

```bash
# from the project root
/test-review --scope tests/
```

The skill will increment `round` in the manifest, archive this round under
`.test-review/archive/2026-05-19T18-15-00Z/`, and start fresh.
````

## `TOOLING_REPORT.md`

Generated by the skill's tooling-detection phase (Claude side: Phase 0.5; Codex side: Phase 4.5).
Lists which recommended tools are installed, which are declared in the project manifest but not
installed, which are missing entirely, plus a Discoveries section from the per-round web-research
pass. Never modifies the project itself — every "missing" entry includes a copy-paste install
snippet the user runs at their discretion.

````markdown
# Test Review — Tooling Report

Generated: 2026-05-19T18:05:00Z Round: 1 Languages detected: python, bash Project managers detected:
pyproject.toml (PEP 621), no Cargo.toml, no package.json Web-research pass: enabled (use
`--skip-web-research` to skip)

## Inventory

Legend: `installed` = binary present + (where applicable) declared in manifest; `manifest-only` =
declared but binary missing; `missing` = not declared and not on PATH; `n/a` = no canonical tool for
this language; `partial` = some sub-tool present.

### Python

| Category        | Default tool      | Status        | Detection                                                                                       |
| --------------- | ----------------- | ------------- | ----------------------------------------------------------------------------------------------- |
| Runner          | `pytest`          | installed     | `pytest --version` → 8.2.0; declared in `pyproject.toml` `[project.optional-dependencies.test]` |
| Parallel runner | `pytest-xdist`    | installed     | `python -c 'import xdist'` → ok                                                                 |
| Coverage        | `pytest-cov`      | installed     | declared, `pytest --cov` works                                                                  |
| Snapshot        | `syrupy`          | missing       | not declared; suggest add                                                                       |
| Property-based  | `hypothesis`      | manifest-only | declared in `pyproject.toml`, binary not callable (env issue?)                                  |
| Mutation        | `mutmut`          | missing       | no binary, not declared                                                                         |
| HTTP fake       | `vcrpy` / `respx` | missing       | no relevant package declared                                                                    |

### Bash

| Category  | Default tool | Status    | Detection                                 |
| --------- | ------------ | --------- | ----------------------------------------- |
| Runner    | `bats-core`  | installed | `bats --version` → 1.10.0                 |
| HTTP fake | `bats-mock`  | missing   | not present as git submodule, not on PATH |

### Cross-cutting

| Concern    | Status     | Notes                                                 |
| ---------- | ---------- | ----------------------------------------------------- |
| Pre-commit | configured | `.pre-commit-config.yaml` exists; pytest hook present |
| CI         | configured | `.github/workflows/test.yml` runs pytest on push      |

## Setup steps for missing tools

Each step below is **opt-in**. Apply the snippet, then re-run `/test-review` to refresh the
inventory.

### 1. Add `syrupy` for snapshot testing

```toml
# pyproject.toml — under [project.optional-dependencies]
test = [
    "pytest>=8",
    "pytest-xdist",
    "pytest-cov",
    "syrupy",            # NEW
]
```

Then: `pip install -e '.[test]'` (or `uv pip install -e '.[test]'`).

### 2. Add `mutmut` for mutation testing

```bash
pip install --user mutmut       # binary installed once per machine
```

Add a Makefile target for repeatability:

```makefile
mutate:
 mutmut run --paths-to-mutate=src/myapp || true
 mutmut results
```

### 3. Add `respx` (HTTP fake for httpx-based projects) — replaces TR-002 mock-only patterns

```toml
# pyproject.toml — under [project.optional-dependencies]
test = [
    # …existing entries…
    "respx",
]
```

### 4. Install `bats-mock` as a git submodule

```bash
git submodule add https://github.com/jasonkarns/bats-mock tests/test_helper/bats-mock
git submodule update --init --recursive
```

[…more steps per missing tool…]

## Discoveries (web-research pass)

Newer or project-specific tools the round-1 web research surfaced. **Advisory only** — none are
added to `REFACTOR_PLAN.md` unless the user promotes them in a follow-up turn.

### `pytest-recording` (Python)

- **Source:** <https://github.com/kiwicom/pytest-recording>
- **Last release:** 2025-09-12
- **Stars:** 2.4k
- **Fit:** modern alternative to `vcrpy` with `pytest`-native syntax (decorators, fixtures,
  in-memory cassettes for httpx). Worth considering if the project already uses pytest and httpx.
- **Duplicates:** `vcrpy`. Reason to prefer: cleaner ergonomics; native `pytest` integration; better
  `httpx` support.

### `pytest-fast-check` (Python)

- **Source:** <https://github.com/example/pytest-fast-check>
- **Last release:** 2025-12-01
- **Stars:** 410
- **Fit:** brings the `fast-check` property-based engine to Python (port of the TS library) with
  shrinking semantics that some users prefer over `hypothesis`. Speculative; surface for awareness,
  not action.

[…more discoveries…]

## Re-run

```bash
/test-review                                   # refresh tooling + findings
/test-review --skip-web-research               # skip web research this round
/test-review --tooling-only                    # tooling inventory only, no lint
```
````

## Codex hand-off prompt (single-block, for printing at the end of Phase 3)

```text
You are running the codex `test-review` skill in implementation mode.

Read these files first:
  - .test-review/MANIFEST.yaml
  - .test-review/REFACTOR_PLAN.md
  - <principles-path from MANIFEST.yaml>

Execute tasks in the order listed in REFACTOR_PLAN.md. Batch by file
(≤5 tasks per batch). After each batch, run the project test suite
(`make test` / `cargo nextest run` / `pytest -n auto` — pick from the
project's Makefile or detect from the language).

Honor every task's flags:
  - requires-user-confirm: true → STOP and request approval.
  - security-sensitive: true → require an explicit human gate.
  - coverage-risk: true → warn the user before applying.

Never auto-update snapshot baselines. Never delete a test without
per-test confirmation. Never silently install dependencies — surface
Suggestions from REFACTOR_PLAN.md as opt-in only.

When done (or aborted), emit .test-review/POST_REFACTOR_REPORT.md per
the codex skill's template, and update MANIFEST.yaml with the
implementation log.
```
