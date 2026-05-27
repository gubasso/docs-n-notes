# Anti-Patterns — Lint Rule Catalog

Walked by Phase 1 of the `test-review` skill. Each rule produces zero or more findings per file,
each with:

- `id` — stable rule ID (e.g. `TR-001`).
- `severity` — `critical` ⛔ / `high` ⚠️ / `info` ℹ️.
- `file:line` — location in the test file.
- `principle` — citation back to the principles file (e.g.
  `08-testing-and-quality/testing-strategy.md:10`).
- `fix` — short, prescriptive suggested fix.

## Table of contents

- [Critical (TR-001 to TR-005) — testing the third-party library](#critical--testing-the-third-party-library)
- [High (TR-010 to TR-019) — isolation, determinism, mocking discipline](#high--isolation-determinism-mocking-discipline)
- [Info (TR-020 to TR-029) — readability, naming, scenario-vs-mechanic balance](#info--readability-naming-scenario-vs-mechanic-balance)
- [Wrapper-specific (TR-030 to TR-039) — argv-contract and subprocess tests](#wrapper-specific--argv-contract-and-subprocess-tests)
- [LLM-era (TR-040 to TR-049) — AI-generated test smells](#llm-era--ai-generated-test-smells)

## Critical — testing the third-party library

These are the dominant failure mode of AI-generated test suites and a common one in human-written
tests. Every one is a direct violation of principle 4 of the principles file.

### TR-001 — Assertion subject is a non-project import

**Detection:** the left-hand side (or sole subject) of an assertion resolves to a symbol that was
imported from a module the project does not own.

```python
# Bad — testing the json library
import json
def test_serializes_widget():
    assert json.dumps({"id": 1}) == '{"id": 1}'
```

```python
# Good — testing your serializer
from myapp.widget import WidgetSerializer
def test_serializes_widget():
    assert WidgetSerializer().serialize(Widget(id=1)) == '{"id": 1}'
```

**Fix:** replace the assertion subject with a project-owned symbol. If the project has no wrapper
around the third-party library yet, extracting one is part of the fix — that wrapper _is_ the
boundary the project should be testing.

**Principle:** `08-testing-and-quality/testing-strategy.md:10` (Principle 4) and
`08-testing-and-quality/testing-strategy.md:#1-assertion-subject-is-a-non-project-import`.

### TR-002 — Mock is the only subject

**Detection:** the test fully stubs an external dependency and the _only_ assertions are against the
stub's recorded call shape. The project's own code is bypassed; nothing exercises it.

```python
# Bad — asserts on the mock, not on fetch_data's behavior
def test_fetch_data():
    m = MagicMock()
    m.get.return_value.json.return_value = {"ok": True}
    with patch("myapp.client.requests", m):
        fetch_data()
    m.get.assert_called_once_with("https://api.example.com/data")
```

```python
# Good — assert on fetch_data's return value (a domain object)
def test_fetch_data_returns_widget():
    fake_http = RecordingHttpFake.serving({"ok": True, "id": 7})
    widget = fetch_data(client=fake_http)
    assert widget == Widget(id=7)
```

**Fix:** replace the mock with a fake (recording HTTP server, in-memory queue, sqlite tempfile,
whichever fits the boundary). Assert on the project's return value or post-state, not on the fake's
recorded calls. The fake's call shape can be a _secondary_ assertion if the argv contract is itself
the test's subject, but it should never be the only one.

**Principle:** `08-testing-and-quality/testing-strategy.md:#2-the-mock-is-the-only-subject`.

### TR-003 — Doc-mirroring

**Detection:** the test body reads as the third-party library's published usage example with minor
renames (variable names, expected values). If pasted into the library's README, it would teach the
library's behavior.

This is hard to detect mechanically — surface it as a finding when:

- Test has minimal arrangement (no project setup).
- The act calls a single third-party API.
- The assertion checks a value the library's own contract guarantees.
- No project type appears in the test body.

**Fix:** delete the test, or convert it into a real integration test that exercises a project
boundary. If the test was teaching documentation, write a docstring instead.

**Principle:** `08-testing-and-quality/testing-strategy.md:#3-doc-mirroring`.

### TR-004 — Mocking your own pure function

**Detection:** a `patch`/`mock`/`Mock.return_value` (or language equivalent) target resolves to a
project-internal pure function — i.e. a function with no side effects that takes inputs and returns
a value.

```python
# Bad — patched a pure function the test could have just called
from unittest.mock import patch
def test_widget_handler():
    with patch("myapp.widget.serialize", return_value='{"id": 1}'):
        result = handle(Widget(id=1))
    assert result == '{"id": 1}'
```

```python
# Good — call serialize in the assertion
from myapp.widget import serialize
def test_widget_handler():
    result = handle(Widget(id=1))
    assert result == serialize(Widget(id=1))   # or a literal expected string
```

**Fix:** remove the patch. Call the pure function directly. If the patch was hiding a coupling
problem, surface it as a separate finding (`TR-014 — implicit collaborator`).

**Principle:** `08-testing-and-quality/testing-strategy.md:335` (anti-pattern list) and
`08-testing-and-quality/testing-strategy.md:#4-mocking-your-own-pure-function`.

### TR-005 — Import-removal test

**Detection:** mentally delete the third-party import that the test sets up. Would the test still
pass?

The mechanical proxy: read the test's body. If every assertion is satisfied by a project-owned
subject, and the third-party import is only referenced inside the arrange section (creating a stub
or patch target), the test fails this heuristic.

This is the _meta-heuristic_ — when TR-001 through TR-004 are not individually triggered but the
test still doesn't exercise the boundary, TR-005 is the catch.

**Fix:** convert the test into one of:

- A true unit test on the project-owned subject (no third-party import needed at all).
- An integration test against a fake or recording stub of the external dependency, with assertions
  on the project's return value or post-state.

**Principle:** `08-testing-and-quality/testing-strategy.md:#5-the-import-removal-test`.

## High — isolation, determinism, mocking discipline

### TR-010 — Shared temp dir across tests

Tests in the same file reuse a top-level `TempDir` or `mktemp` result. Order-dependent failures and
parallel-run breakage.

**Fix:** every test gets its own fixture; fixture builds a fresh tempdir.

**Principle:**
`08-testing-and-quality/testing-strategy.md:#test-isolation--the-single-most-important-rule`.

### TR-011 — Global env / cwd mutation

Test calls `os.environ[...] = ...`, `os.chdir(...)`, `std::env::set_var(...)` outside a scoped
fixture. Leaks across the suite.

**Fix:** mutate env in a fixture that restores on teardown, or use `env_clear` + curated env on a
subprocess invocation.

**Principle:** `08-testing-and-quality/testing-strategy.md:332` (anti-pattern list).

### TR-012 — Mocking the filesystem

`mock_open`, `pyfakefs`, or equivalent. Real tempdirs are cheaper, more accurate, and don't drift
from real OS behavior.

**Fix:** delete the FS mock; use a real tempdir.

**Principle:** `08-testing-and-quality/testing-strategy.md:334`.

### TR-013 — Real clock / sleep in test

`time.sleep`, `thread::sleep`, `setTimeout`. Flaky, slow, hides race conditions.

**Fix:** inject a `Clock` via `AppContext`; advance it in the test. Or use the framework's
fake-clock primitive.

**Principle:** `08-testing-and-quality/testing-strategy.md:338`.

### TR-014 — Implicit collaborator

The test mocks a collaborator that wasn't injected — patches it via module path. Tells you the
production code has hidden coupling.

**Fix:** make the collaborator an explicit parameter (constructor or function arg). The test then
passes a fake without patching.

**Principle:** Principle 3 (behavior over implementation) + production-code design smell.

### TR-015 — Brittle exact-match assertions

Test uses exact-equality on long stdout / long strings, breaking on harmless whitespace/format
changes. Snapshot tests exist for this.

**Fix:** use a `contains` matcher for prose; use a snapshot for structured output.

**Principle:** `08-testing-and-quality/testing-strategy.md:174` (string-contains predicates for
stdout).

### TR-016 — Snapshot abuse

Snapshot contains data that changes every run (timestamps, UUIDs, ANSI escapes, absolute paths).
Test passes the first time and fails on every commit until someone updates the snapshot.

**Fix:** redact volatile fields before snapshotting; or pin clock / UUID generator / cwd / NO_COLOR
in the fixture.

**Principle:** `08-testing-and-quality/testing-strategy.md:#snapshot-tests`.

### TR-017 — Untested `--help`

CLI changes pass review without the `--help` text being verified. Easy to break, easy to snapshot.

**Fix:** add a snapshot test on `--help` (and per-subcommand `--help`).

**Principle:** `08-testing-and-quality/testing-strategy.md:336`.

### TR-018 — Monolithic integration test

One integration test runs every subcommand. When it fails, no signal about which command broke.

**Fix:** split into one file per subcommand (`tests/cmd_<name>.{ext}`).

**Principle:** `08-testing-and-quality/testing-strategy.md:333`.

### TR-019 — No isolation primitive

Test file has no fixture; every test does its own `tempfile.mkdtemp` + `setenv` boilerplate. Drift
across tests in the same file; missed `env_clear` somewhere.

**Fix:** extract a `Fixture` builder into `tests/support/`. Every test starts with `fx = Fixture()`.

**Principle:**
`08-testing-and-quality/testing-strategy.md:#test-isolation--the-single-most-important-rule`.

## Info — readability, naming, scenario-vs-mechanic balance

### TR-020 — Over-DRY scenarios

Test bodies have collapsed into one-liners that call into shared helpers; reader cannot tell what's
being tested without opening the helpers.

**Fix:** inline the scenario back into the test. Keep helpers for _mechanics_ (fixture, custom
matcher), not for _what_ the test asserts.

**Principle:** `08-testing-and-quality/testing-strategy.md:#dry-vs-damp-in-tests`.

### TR-021 — Test name describes implementation, not behavior

`test_serialize_calls_dumps` instead of `test_widget_renders_as_json`. Name drifts when the
implementation changes.

**Fix:** rename to describe the externally-observable behavior the test pins down.

**Principle:** Principle 3 (behavior over implementation) + Principle 7 (readable assertions).

### TR-022 — Missing classify (golden / error / edge)

Subcommand has fewer than three integration tests; the missing ones are golden path, common error,
edge case.

**Fix:** add the missing tests so each subcommand has at least the three classes.

**Principle:** `08-testing-and-quality/testing-strategy.md:175`.

### TR-023 — Coverage-chasing test

Test exists only to bump a line-coverage number — exercises a trivial getter or auto-generated code
without any non-trivial assertion.

**Fix:** delete. Coverage is not a goal. See
`08-testing-and-quality/testing-strategy.md:#coverage-philosophy`.

**Principle:** Principle 6 (meaningful coverage).

### TR-024 — Test doc-comment / docstring is empty or wrong

Test has a docstring that says "tests the widget" — useless.

**Fix:** delete the docstring (the name is the doc), or rewrite to say _what behavior_ is locked
down.

**Principle:** Principle 7.

## Wrapper-specific — argv-contract and subprocess tests

These rules apply only when the project is a CLI that wraps another binary. Cross-reference:
`06-cli-wrapper-design/process-and-posix.md#9-testability`.

### TR-030 — Subprocess library is the only subject

Wrapper test stubs `Command::output` / `subprocess.run` / `exec.Command` and asserts only on the
stub's recorded calls. This is TR-002 specialized to wrappers; surface separately because the fix is
wrapper-specific (use a recording stub on PATH, not a mock).

**Fix:** convert to argv-contract integration test (`assert_argv_equals` against a recording stub
binary on PATH).

**Principle:**
`08-testing-and-quality/testing-strategy.md:#argv-contract-tests-for-clis-that-wrap-other-binaries`.

### TR-031 — Missing signal/exit-code matrix

Wrapper has no test for `SIGINT` → `128 + SIGINT`, `SIGTERM` → propagated, child exit-code
passthrough.

**Fix:** add per-signal tests with a fake child that sleeps then exits.

**Principle:** `06-cli-wrapper-design/process-and-posix.md:403`.

### TR-032 — Untested `--` sentinel handling

Wrapper passes args through to a child but has no test that `--` is preserved.

**Fix:** add an argv-contract test that asserts the `--` separator is propagated to the child argv.

**Principle:** `06-cli-wrapper-design/checklist.md:127`.

## LLM-era — AI-generated test smells

These tend to co-occur with TR-001 / TR-002 / TR-003 but are surfaced separately so the reviewer can
recognize the _pattern_ of an AI-generated suite.

### TR-040 — Tests in alphabetical-method order

Suite is organized by method name on the SUT class (`test_widget_init`, `test_widget_load`,
`test_widget_save`), not by behavior. Indicates the test writer (often an agent) walked the class
API instead of the user-visible behavior.

**Fix:** reorganize by behavior (`test_widget_creation_*`, `test_widget_persistence_*`).

### TR-041 — Excessive mock-everything pattern

Test mocks every collaborator including the project's own modules. Almost guaranteed to also trigger
TR-002 and TR-004.

**Fix:** start over from the principles file. Mock only at architectural boundaries.

### TR-042 — Coverage without mutation kill

(Detected by running mutation testing in the codex twin's verify phase, not by static analysis here.
Surfaced as a recommendation in REFACTOR_PLAN.md when the language has a mutation-testing tool
available.)

**Fix:** see the Suggestions section of REFACTOR_PLAN.md for the per-language mutation tool.

---

When a finding triggers, the skill writes one record per finding into `FINDINGS.md` (skeleton in
`references/templates.md`). The codex twin reads the resulting `REFACTOR_PLAN.md` and acts on the
tasks, never on the raw findings.
