---
digest-of: tech/programming/testing
last-synced: 2026-05-27
source-files:
  - README.md
  - testing-principles.md
  - test-anti-patterns.md
  - testing-tool-matrix.md
  - test-report-templates.md
token-estimate: 1500
---

# AGENTS

## Scope

Testing principles, anti-pattern catalog, per-language tool matrix, and output templates for the
`test-review` skill.

## Key Points

### Non-Negotiable Principles

1. Best practices first (language-community idioms).
2. Test major public APIs and core interfaces.
3. Test behavior and contracts, not implementation details.
4. Do not test third-party libraries.
5. Deterministic and fast (no shared state, no real clock/network).
6. Meaningful coverage driven by risk, not line-count.
7. Clear names, minimal mocking, readable assertions.

### Test Shape Models

- **Pyramid** (CLI/library): wide unit base, narrowing integration, thin E2E apex.
- **Trophy** (I/O orchestration): integration-heavy on a static-analysis base.
- **Honeycomb** (microservices): equal unit + contract + E2E.

### Five Heuristics for "Testing the Third-Party Library"

- TR-001: Assertion subject is a non-project import.
- TR-002: Mock is the only subject (project code bypassed).
- TR-003: Doc-mirroring (test reads like library's README).
- TR-004: Mocking your own pure function.
- TR-005: Import-removal test (delete the import; test still passes).

### Anti-Pattern Catalog (by severity)

- **Critical** (TR-001-005): Third-party library testing.
- **High** (TR-010-019): Shared tempdir, global env mutation, mocking filesystem, sleep in tests,
  implicit collaborator, brittle exact-match, snapshot abuse, untested `--help`, monolithic
  integration, no isolation primitive.
- **Info** (TR-020-024): Over-DRY scenarios, implementation-named tests, missing golden/error/edge
  classify, coverage-chasing, empty docstrings.
- **Wrapper-specific** (TR-030-032): Subprocess mock as only subject, missing signal/exit-code
  matrix, untested `--` sentinel.
- **LLM-era** (TR-040-042): Alphabetical-method order, mock-everything, coverage without mutation
  kill.

### Tool Matrix Defaults

| Language | Runner           | Snapshot        | Property         | Mutation        | HTTP fake       |
| -------- | ---------------- | --------------- | ---------------- | --------------- | --------------- |
| Rust     | `cargo nextest`  | `insta`         | `proptest`       | `cargo-mutants` | `wiremock`      |
| Python   | `pytest -n auto` | `syrupy`        | `hypothesis`     | `mutmut`        | `respx`/`vcrpy` |
| TS/JS    | `vitest`         | vitest-snapshot | `fast-check`     | `stryker`       | `msw`           |
| Go       | `go test -race`  | `goldie`        | `gopter`/`rapid` | `gremlins`      | `httpmock`      |
| Bash     | `bats-core`      | `assert_output` | table-driven     | n/a             | `bats-mock`     |

### Mock Defaults

- Filesystem: real sandboxed tempdir, never mock.
- Clock: inject `Clock` trait.
- Network HTTP: fake at adapter trait or recording library.
- Database: sqlite tempfile in-process.
- Environment: `env_clear` + curated env.

## Source Map

| Topic                                                       | File                       |
| ----------------------------------------------------------- | -------------------------- |
| Principles, pyramid, what-to-mock table                     | `testing-principles.md`    |
| Lint rule catalog TR-001 through TR-042                     | `test-anti-patterns.md`    |
| Per-language tool matrix and install snippets               | `testing-tool-matrix.md`   |
| MANIFEST, FINDINGS, REFACTOR_PLAN, TOOLING_REPORT skeletons | `test-report-templates.md` |

## Maintenance Notes

- Canonical principles source is
  `tech/programming/cli-design/08-testing-and-quality/testing-strategy.md`; this directory carries
  the embedded fallback and skill-specific artifacts.
- Tool matrix should be refreshed when major versions of testing tools release.
