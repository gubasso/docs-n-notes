# Tool Matrix — Per-Language Recommendations

Loaded by Phase 3 of the `test-review` skill when generating the **Suggestions** section of
`REFACTOR_PLAN.md`. Mirrors the canonical reference at
`tech/programming/cli-design/08-testing-and-quality/testing-tools.md`. Refresh from canonical when
adding a new language.

The rule for surfacing suggestions: **never silently install.** Every suggestion in REFACTOR_PLAN.md
is a copy-paste snippet the user (or the codex twin, with user approval) chooses to apply.

## Opinionated defaults — "if in doubt, start here"

| Language        | Runner                    | Snapshot                | Property-based      | Mutation        | HTTP fake          |
| --------------- | ------------------------- | ----------------------- | ------------------- | --------------- | ------------------ |
| Rust            | `cargo nextest`           | `insta` (`cargo-insta`) | `proptest`          | `cargo-mutants` | `wiremock`         |
| Python          | `pytest` (`-n auto`)      | `syrupy`                | `hypothesis`        | `mutmut`        | `vcrpy` or `respx` |
| TypeScript / JS | `vitest`                  | `vitest`-snapshot       | `fast-check`        | `stryker`       | `msw`              |
| Go              | `go test ./...` (`-race`) | `goldie`                | `gopter` or `rapid` | `gremlins`      | `httpmock`         |
| Bash            | `bats-core`               | `bats` `assert_output`  | n/a (table-driven)  | n/a             | `bats-mock`        |

## Detection commands — is the tool already set up?

Used by the skill's tooling-detection phase. Each cell is a probe that exits non-zero (or returns
empty) when the tool is **not** installed or not wired into the project. Run all probes in parallel;
classify each tool as `installed`, `manifest-only` (declared in pyproject.toml / Cargo.toml /
package.json / go.mod but binary not on PATH), `not-installed`, or `n/a` (no canonical tool for the
language).

| Category                | Rust                                                                                       | Python                                                                | TypeScript / JS                                                                                         | Go                                              | Bash                                      |
| ----------------------- | ------------------------------------------------------------------------------------------ | --------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------- | ----------------------------------------------- | ----------------------------------------- |
| Runner present (binary) | `cargo --version && (cargo nextest --version 2>/dev/null \|\| echo missing)`               | `python -c 'import pytest' 2>/dev/null \|\| echo missing`             | `pnpm exec vitest --version 2>/dev/null \|\| npx vitest --version 2>/dev/null \|\| echo missing`        | `go version`                                    | `command -v bats`                         |
| Runner manifest entry   | `grep -E '(nextest\|test)' Cargo.toml`                                                     | `grep -E '^pytest' pyproject.toml \|\| grep pytest requirements*.txt` | `jq -r '.devDependencies.vitest // .devDependencies.jest' package.json`                                 | n/a (stdlib)                                    | n/a (binary check is enough)              |
| Snapshot                | `grep -E '^insta' Cargo.toml`                                                              | `grep -E 'syrupy\|pytest-snapshot' pyproject.toml`                    | `jq -r '.devDependencies \| with_entries(select(.key \| test("snapshot\|vitest\|jest")))' package.json` | `grep -E 'goldie\|cupaloy' go.mod`              | n/a                                       |
| Property-based          | `grep -E '^proptest\|^quickcheck' Cargo.toml`                                              | `grep hypothesis pyproject.toml`                                      | `jq -r '.devDependencies."fast-check"' package.json`                                                    | `grep -E 'gopter\|rapid' go.mod`                | n/a                                       |
| Mutation                | `command -v cargo-mutants`                                                                 | `command -v mutmut`                                                   | `command -v stryker \|\| jq -r '.devDependencies."@stryker-mutator/core"' package.json`                 | `command -v gremlins`                           | n/a                                       |
| HTTP fake               | `grep -E 'wiremock\|mockito\|httpmock' Cargo.toml`                                         | `grep -E 'vcrpy\|respx\|responses' pyproject.toml`                    | `jq -r '.devDependencies \| with_entries(select(.key \| test("msw\|nock\|pollyjs")))' package.json`     | `grep -E 'httpmock\|gock' go.mod`               | `command -v bats-mock`                    |
| Coverage                | `command -v cargo-llvm-cov \|\| grep tarpaulin Cargo.toml`                                 | `grep -E 'pytest-cov\|coverage' pyproject.toml`                       | `jq -r '.devDependencies \| with_entries(select(.key \| test("c8\|nyc\|istanbul")))' package.json`      | `go help test 2>&1 \| grep -q cover && echo ok` | `command -v kcov \|\| command -v bashcov` |
| Pre-commit configured   | `test -f .pre-commit-config.yaml` (any language)                                           |                                                                       |                                                                                                         |                                                 |                                           |
| CI configured           | `test -d .github/workflows -o -f .gitlab-ci.yml -o -f .circleci/config.yml` (any language) |                                                                       |                                                                                                         |                                                 |                                           |

If `jq` is not available, fall back to `grep -E '"vitest":' package.json`-style probes. The exact
command matters less than the answer (`installed` / `manifest-only` / `not-installed`).

Project-config-file lookup precedence (per language) for "is this declared somewhere":

- **Python:** `pyproject.toml` (PEP 621 `[project.optional-dependencies.test]`, Poetry
  `[tool.poetry.group.dev.dependencies]`, PDM `[tool.pdm.dev-dependencies.test]`), then
  `requirements*.txt`, then `setup.cfg`.
- **Rust:** `Cargo.toml` `[dev-dependencies]` + workspace inheritance.
- **TypeScript/JS:** `package.json` `devDependencies` + `peerDependencies`; pnpm/yarn workspace
  roots.
- **Go:** `go.mod` (test-only imports are still tracked).
- **Bash:** binary presence on `PATH`; project may have a `bats/` git submodule.

## When to suggest each tool category

| Finding pattern                                       | Suggest tool category                                                                                               |
| ----------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------- |
| `TR-001` / `TR-002` / `TR-005` widespread             | Recording HTTP fake (vcrpy / msw / wiremock) — replaces mock-only patterns with real-wire-format fakes.             |
| `TR-016` snapshot abuse                               | Snapshot tool with redaction (`syrupy` filters, `insta` redactions).                                                |
| Parser / codec / state machine without property tests | Property-based testing (`hypothesis` / `proptest` / `fast-check`).                                                  |
| High coverage, low signal (suspected; codex verifies) | Mutation testing (`mutmut` / `cargo-mutants` / `stryker`).                                                          |
| `TR-019` no isolation primitive                       | Language-appropriate fixture pattern; reference the `Fixture` snippet in `08-testing-and-quality/testing-tools.md`. |
| `TR-030` wrapper-mocks-subprocess                     | Recording stub binary on PATH + `assert_argv_equals`.                                                               |

## Pre-commit / CI tier suggestions

For projects without a `.pre-commit-config.yaml`, REFACTOR_PLAN.md's Suggestions section can include
a copy-paste hook tailored to the detected language:

### Python

```yaml
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

### Rust

```yaml
- repo: local
  hooks:
    - id: cargo-nextest-unit
      name: cargo nextest (lib only)
      entry: cargo
      language: system
      args: [nextest, run, --lib, --no-fail-fast]
      types_or: [rust, toml]
      pass_filenames: false
      stages: [pre-commit]
```

### TypeScript

```yaml
- repo: local
  hooks:
    - id: vitest-unit
      name: vitest run (unit)
      entry: pnpm
      language: system
      args: [vitest, run, --reporter=dot, src/]
      types: [ts]
      pass_filenames: false
      stages: [pre-commit]
```

### Bash

```yaml
- repo: local
  hooks:
    - id: bats-unit
      name: bats (unit)
      entry: bats
      language: system
      args: [tests/unit]
      types: [shell]
      pass_filenames: false
      stages: [pre-commit]
```

## Mutation-testing schedule snippet

For projects that want mutation testing on a nightly schedule (the only sensible cadence — see
`08-testing-and-quality/testing-strategy.md:#mutation-testing-as-quality-gate`):

```yaml
# .github/workflows/mutation.yml
name: mutation-testing
on:
  schedule: [{ cron: '0 4 * * *' }]
  workflow_dispatch: {}

jobs:
  mutate:
    runs-on: ubuntu-latest
    timeout-minutes: 120
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-python@v5
        with: { python-version: '3.x' }
      - run: pip install -e . mutmut
      - run: mutmut run --paths-to-mutate=src/myapp || true
      - run: mutmut results
```

Adapt the `mutmut` lines per language. The `|| true` is intentional: surviving mutants are reported,
not a gate, until the score is stable on a critical module.

## Makefile / justfile target snippet

```just
test:               (test-unit) (test-integration)
test-unit:          pytest tests/unit -n auto
test-integration:   pytest tests/integration -n auto
test-e2e:           pytest tests/e2e
cover:              pytest --cov=myapp --cov-report=term-missing
mutate:             mutmut run && mutmut results
```

Rust:

```just
test:        cargo nextest run
test-int:    cargo nextest run --test '*'
cover:       cargo llvm-cov --all-features --workspace --lcov --output-path lcov.info
mutate:      cargo mutants --in-place --no-shuffle
```

## Install snippets — tailored per project manager

Used by `TOOLING_REPORT.md` setup steps. Each snippet is a copy-paste block the user (or the codex
twin with explicit approval) applies once to add a missing tool. **Never auto-applied** — see Rule 8
of the skills.

### Python — `pyproject.toml`

```toml
[project.optional-dependencies]
test = [
    "pytest>=8",
    "pytest-xdist",
    "pytest-cov",
    "syrupy",                 # snapshot
    "hypothesis",             # property-based
    "respx",                  # HTTP fake (httpx) — use vcrpy for requests
]
dev = ["mutmut"]              # mutation testing — runs out-of-tree
```

Install: `pip install -e '.[test,dev]'` or `uv pip install -e '.[test,dev]'`.

### Rust — `Cargo.toml`

```toml
[dev-dependencies]
insta      = { version = "1", features = ["yaml"] }
proptest   = "1"
wiremock   = "0.6"

# Binary tools (install once per machine, not per project):
# cargo install cargo-nextest cargo-mutants cargo-llvm-cov cargo-insta
```

### TypeScript / JS — `package.json` `devDependencies`

```json
{
  "devDependencies": {
    "vitest": "^2",
    "fast-check": "^3",
    "msw": "^2",
    "@stryker-mutator/core": "^8",
    "@stryker-mutator/vitest-runner": "^8"
  }
}
```

Install: `pnpm add -D vitest fast-check msw @stryker-mutator/core @stryker-mutator/vitest-runner`
(or `npm i -D …`).

### Go — go.mod

```text
go get -t github.com/leanovate/gopter
go get -t github.com/sebdah/goldie/v2
go get -t github.com/jarcoal/httpmock
go install github.com/go-gremlins/gremlins/cmd/gremlins@latest
```

### Bash — system / per-project

```bash
# Ubuntu/Debian:  sudo apt-get install bats kcov
# macOS:           brew install bats-core kcov
# bats-mock:       git submodule add https://github.com/jasonkarns/bats-mock tests/test_helper/bats-mock
```

## Per-round web research instructions

When the skill runs its web research pass, prompt the dispatched research agent (or the WebSearch
tool directly) along the lines of:

```text
For a project written in <language(s)>, identify testing tools that
were released or substantially updated in the last 12 months and may
be relevant for: mutation testing, property-based testing, recording
HTTP fakes, snapshot testing, and CLI argv-contract verification.
Prefer official sources, popular GitHub repos (>1k stars or
active-monthly), and authoritative writeups (martinfowler.com,
kentcdodds.com, hynek.me, vladimirkhorikov.com).

Project context (one line each):
  - frameworks detected: <list>
  - test runners detected: <list>
  - any HTTP client / DB / queue libraries detected: <list>

For each candidate tool report:
  - name, language, license, last release date
  - one-paragraph fit-for-this-project rationale
  - canonical URL (docs root)
  - whether it duplicates a tool already in this matrix; if yes, why
    a project might prefer the new one

Skip tools already in the opinionated defaults table unless a major
2025/2026 release substantively changed their behavior.
```

The skill writes the research output into the **Discoveries** section of `TOOLING_REPORT.md`. Each
discovery is advisory — the user decides whether to incorporate it. Discoveries do not become tasks
in `REFACTOR_PLAN.md` unless the user explicitly promotes them.

## Authority

For the full per-language matrix (CLI testing libraries, contract testing, coverage tools, recording
stubs in their entirety) the canonical reference is the user's
`tech/programming/cli-design/08-testing-and-quality/testing-tools.md`. Read that file when the
project's needs go beyond the opinionated defaults above.
