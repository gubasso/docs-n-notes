# 08 — Testing Strategy

The CLI testing pyramid. Where each kind of test lives, what it covers, how to keep tests isolated, and why every subcommand earns one integration test from day one.

## Non-negotiable principles

1. **Best practices first.** Clean, maintainable tests, written in the idioms the language community considers standard.
2. **Test major public APIs and core interfaces** — the behavior that defines the product, not incidental helpers.
3. **Test behavior and contracts, not implementation details.** Don't overfit to private internals; if you can refactor without changing the public contract, the test should still pass.
4. **Don't test third-party libraries.** Assume they're correct. Mock or fake them at their boundary (see [What to mock, what not to mock](#what-to-mock-what-not-to-mock)).
5. **Deterministic and fast.** Isolate side effects with fixtures; no shared state, no real clock, no network, no order dependence.
6. **Meaningful coverage driven by risk and impact**, not line-count. 100% coverage of trivial getters is wasteful; cover what breaks production.
7. **Clear names, minimal mocking, readable assertions.** A test reads as documentation of the contract it locks down.

Every rule below is an application of one of these.

## The pyramid

```
                 ▲
                 |   compile-fail / typestate    ◄── only when typestate exists
                 |
                 |   integration (one per subcmd) ◄── against the real binary
                 |
                 |   snapshot (structured output) ◄── inside integration suite
                 |
                 |   unit (colocated)             ◄── every module with logic
                 ▼
```

- **Unit** — colocated tests inside each module. Cover newtype constructors, parse-shape → runtime-shape projection, state-machine transitions, pure pipelines. Tests live next to the code they test, share its visibility, and run on every change.
- **Integration** — one process-level test file per subcommand. Spawns the real binary in a sandboxed environment, asserts on `stdout` / `stderr` / exit code / side effects. The most valuable rung of the pyramid for CLIs.
- **Snapshot** — assertions on long structured output (JSON, YAML, tables, full error messages). Lives inside the unit and integration suites.
- **Compile-fail / typestate** — only when you have a typestate API (builder where the type changes per `.with_x()` call) and want to lock down invalid call sequences. Skip otherwise.

End-to-end black-box tests sit above this pyramid and run in a separate CI pipeline; they're useful for distribution-shape and live-dependency contracts but are not a substitute for the per-subcommand integration tests. See [E2E tests](#e2e-tests).

## Tiers at a glance

| Tier         | What it tests                                                              | External deps                                                       | Speed          | Runs in     |
|--------------|----------------------------------------------------------------------------|---------------------------------------------------------------------|----------------|-------------|
| Unit         | One function/module in isolation                                           | None (or fully faked)                                               | ms             | pre-commit  |
| Integration  | Two-or-more components together, OR your code's seam to one external dep   | Stubs/fakes of the boundary, or a real contained dep                | tens of ms – s | pre-push    |
| E2E (system) | The whole product through its user-facing entry point, against real state  | The actual real things (live binary, real network, real container)  | s – min        | CI only     |

**The framing that trips people up: integration ≠ "touches real things." Integration = "tests the interaction between things."**

A test that asserts your CLI wrapper passes the right argv to `podman` — with `podman` replaced by a recording stub — is *integration*, not unit. It tests the seam between two components (your argv builder and the subprocess executor), even though no live `podman` runs. See [Argv-contract tests](#argv-contract-tests-for-clis-that-wrap-other-binaries).

A test that runs the real binary, which spawns real `podman`, which launches a real container — that's *E2E*. See [E2E tests](#e2e-tests).

## Test isolation — the single most important rule

Every test runs in a **clean, hermetic environment**:

- Fresh temporary directory (no test ever writes to `$HOME`, the real config dir, or a shared fixture).
- Cleared environment variables — every CLI inherits the parent shell's env, so an active `RUST_LOG=trace` in your shell will break CI snapshots if tests don't scrub.
- No network calls. Mock the adapter, or use a recording library like `vcr`.
- No clock dependencies. Use the abstracted `Clock` from `AppContext` so tests can pin the time.

The defense against test pollution is a shared `support/` module that builds a per-test fixture:

```python
# tests/support.py
class Fixture:
    def __init__(self):
        self.tmp = tempfile.mkdtemp()
        self.home = os.path.join(self.tmp, "home")
        os.makedirs(self.home, exist_ok=True)

    def cmd(self, *args):
        env = {"HOME": self.home, "PATH": os.environ["PATH"]}  # curated env
        return subprocess.run(["myapp", *args], env=env, capture_output=True)
```

```rust
// tests/support/mod.rs
pub struct Fixture {
    pub tmp: TempDir,
    pub home: PathBuf,
}

impl Fixture {
    pub fn cmd(&self) -> assert_cmd::Command {
        let mut c = assert_cmd::Command::cargo_bin("myapp").unwrap();
        c.env_clear()
            .env("HOME", &self.home)
            .env("PATH", std::env::var_os("PATH").unwrap());
        c
    }
}
```

`env_clear` is non-negotiable. Without it, your local shell environment leaks into every test.

## Unit tests

Live colocated, named after behavior not implementation.

```python
# src/widget.py
class WidgetId:
    @classmethod
    def try_new(cls, s: str) -> "WidgetId": ...

# tests/test_widget.py — or a `tests/` block inline if your language supports it
def test_widget_id_rejects_empty():
    with pytest.raises(ValueError):
        WidgetId.try_new("")
```

```rust
// src/commands/widget.rs

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn from_cli_parses_glob() {
        let args = WidgetArgs { id: None, dry_run: false, filter: Some("*.txt".into()) };
        let req = Request::from_cli(args).unwrap();
        assert!(req.filter.is_some());
    }
}
```

**Targets**:

- Every parse-shape → runtime-shape projection (one test per illegal combination).
- Every newtype constructor (boundary inputs, invalid inputs).
- Every state-machine transition (valid + invalid).
- Pure transforms (rendering, formatting, parsing).

**Non-targets**:

- Stateful integration of multiple components — that's integration territory.
- Anything that talks to a real adapter — use a fake.

## Integration tests — one per subcommand

The contract: when a developer adds subcommand `widget`, they also add `tests/cmd_widget.<ext>`. The compiler / linter can't enforce this; code review does.

```rust
// tests/cmd_widget.rs

#[test]
fn widget_dry_run_does_not_modify_state() {
    let fixture = Fixture::new();
    fixture.cmd()
        .arg("widget").arg("--dry-run")
        .assert()
        .success()
        .stdout(predicate::str::contains("would create"));
    assert!(fixture.tmp.path().read_dir().unwrap().next().is_none());
}
```

```python
# tests/test_cmd_widget.py

def test_widget_dry_run_does_not_modify_state():
    fixture = Fixture()
    result = fixture.cmd("widget", "--dry-run")
    assert result.returncode == 0
    assert b"would create" in result.stdout
    assert not list(fixture.work_dir.iterdir())
```

**Rules**:

- One file per subcommand. Test names describe behavior, not implementation.
- Every test gets its own temp dir. Never share state.
- Use string-contains predicates for stdout matching; reserve exact-equality for tiny stable strings.
- Cover at least: golden path, the most common error path, the most common edge case (empty input, --help).

## Argv-contract tests (for CLIs that wrap other binaries)

When your CLI invokes a subprocess (`podman`, `git`, `ssh`, `kubectl`), the argv you construct *is* a public contract. Lock it down with an integration test that replaces the child with a recording stub and asserts on the argv:

```bash
# Replace `podman` on PATH with a stub that records argv as JSON.
fixture::with_recording_stub podman
run mycli ws up --name foo --mem 4G
[ "$status" -eq 0 ]
assert_argv_equals podman '["run","--name","foo","--memory","4G",...]'
```

This is **integration**, not unit: it tests the seam between the argv builder and the subprocess executor. The fact that no live `podman` ran doesn't change its tier — what matters is that two components were composed.

Cross-reference: the Rust/Zig wrapper testing patterns (`Spawner` trait, golden argv snapshots) live in [06 — CLI Wrapper Design § 9 Testability](06-cli-wrapper-design/process-and-posix.md#9-testability).

## Snapshot tests

For any structured output you'd otherwise verify with a hand-maintained 20-line assertion:

```rust
#[test]
fn widget_report_renders() {
    let report = make_test_report();
    insta::assert_yaml_snapshot!(report);
}
```

```python
def test_widget_report_renders(snapshot):
    report = make_test_report()
    snapshot.assert_match(report.to_yaml(), "widget_report.yaml")
```

**When to use**:

- JSON/YAML output from `--format json`.
- Rendered tables.
- Long error messages with chains.
- CLI help text (catches accidental regressions in `--help`).

**Review snapshot diffs as carefully as code diffs** — they're behavior, not implementation noise.

## Compile-fail / typestate (optional)

Only when you have a typestate API that should reject certain call sequences at compile time. In Rust: `trybuild`. In Python: not idiomatic; skip.

```rust
// tests/trybuild.rs
#[test]
fn ui() {
    let t = trybuild::TestCases::new();
    t.compile_fail("tests/trybuild/*.rs");
}
```

If your codebase has no typestate, omit this rung entirely. It exists to lock down a deliberate compile-time invariant — not as general-purpose API regression catching.

## E2E tests

End-to-end tests run the whole product through its user-facing entry point against real external systems: real subprocess execution, real network, real container runtime, real filesystem mounts.

**When to write them:**

- Distribution-shape: the binary builds, installs, and launches on every supported OS.
- Contract with a live external dependency that can't be faithfully faked (real container runtime, real cloud API).
- Catastrophic regressions you can't catch otherwise (e.g., the binary crashes immediately on macOS due to a dynamic-linker bug).

**When not to write them:**

- Anywhere an integration test with a fake would catch the same regression. E2E is the slowest, flakiest tier — reach for it only when fakes can't model the behavior.

**Where they run:**

- CI only. Never in pre-commit or pre-push: too slow, too dependent on host state, too flaky to gate local commits.
- A separate CI job from unit + integration, ideally per-OS.

**Worked example — a CLI that launches a container:**

```bash
# tests/e2e/cmd_ws_up.bats
@test "ws up launches a real krun container and exec works" {
  skip_if_no_podman
  run dctl ws up --name e2e-smoke
  [ "$status" -eq 0 ]

  run podman ps --filter name=e2e-smoke --format '{{.Status}}'
  [ "$status" -eq 0 ]
  [[ "$output" == Up* ]]

  run dctl ws exec e2e-smoke -- echo hello
  [ "$status" -eq 0 ]
  [ "$output" = "hello" ]
}

teardown() {
  podman rm -f e2e-smoke 2>/dev/null || true
}
```

The same shape applies in any language: invoke the installed binary, assert on real external state (`podman ps`), clean up. If the test can pass without ever touching the live dependency, it isn't E2E — relabel it integration.

## What to mock, what not to mock

| Subject | Default |
|---------|---------|
| Filesystem | Real, sandboxed in tempdir. Don't mock. |
| Network HTTP | Mock at the adapter trait. Or use a recording library (vcr-style). |
| Clock / time | Mock via the `Clock` trait on `AppContext`. |
| Subprocess invocations (wrapped CLIs) | Mock at the `Process` adapter trait. |
| Database | Use a sqlite tempfile in-process; don't run a real server in tests. |
| Random | Inject a seeded RNG into `AppContext`. |
| Environment variables | Use `env_clear` + curated env in fixtures (never modify global env in a test). |
| CLI subprocess argv contract | Replace the child with a recording stub; assert on argv. This is an integration test, not a unit test. |

Test pollution from a live process modifying global state is the #1 source of flaky CI. Treat `os.environ`, `chdir`, and global singletons as radioactive in tests.

## Test runner

Use a parallel-by-default runner with fail-fast and a flat summary.

| Language | Runner | Why |
|----------|--------|-----|
| Rust | `cargo nextest` | Parallel, fail-fast, flat summary. `cargo test` is fine but slower and noisier. |
| Python | `pytest` with `-n auto` (pytest-xdist) | Parallel by default. |
| Go | `go test ./...` with `-parallel N` | Built-in. |
| Bash | `bats-core` | Standard. |

Wire it through a one-liner (`just test`, `make test`, `task test`). New contributors find it immediately.

## CI essentials

- Lint (clippy / ruff / shellcheck) → format-check (rustfmt / black / shfmt) → unit + integration tests → coverage gate.
- Cache the dependency build between runs.
- Run on at least one Linux + one macOS runner if the CLI is end-user-facing.
- Lock the toolchain version (`rust-toolchain.toml`, `.python-version`, `go.mod` toolchain directive).
- Fail loudly on warnings (`-Dwarnings` / `--strict`); don't paper over with global allows.
- **Tier-to-hook mapping**:
  - **pre-commit**: unit tests only (parallel, sub-second budget).
  - **pre-push**: unit + integration (still parallel, single-digit-seconds budget).
  - **CI**: everything — unit, integration, E2E, lint, format-check, coverage gate.

## Coverage philosophy

Coverage is a tool, not a goal. Aim for **behavior coverage of high-risk paths** — parse errors, state-machine transitions, error-handling branches, public API contracts — driven by risk and impact, not by chasing a line-count percentage.

- 100% line coverage of trivial getters or generated code is waste.
- 60% line coverage that hits every error branch and every documented exit code is excellent.
- A coverage gate in CI is fine as a *floor* against accidental regressions; it should never be the metric you optimize.

If a coverage report shows an uncovered branch in a critical path (error handling, security-sensitive code, the exit-code matrix), add a test. If it shows uncovered branches in trivial helpers, ignore.

## Anti-patterns

- **Tests that share a temp dir.** Order-dependent, fragile, painful to debug.
- **Tests that mutate global env / cwd.** Leaks across the suite.
- **One giant integration test that runs every subcommand.** Hides which command broke. Split per file.
- **Mocking the filesystem.** Use a real tempdir.
- **Mocking your own pure functions.** Test them directly.
- **Letting `--help` text drift untested.** Snapshot it.
- **Skipping the integration test for "trivial" subcommands.** Trivial today, regression source tomorrow.
- **Sleeping in tests.** Use the abstracted `Clock` instead.

## See also

- [00 — Architecture](00-architecture.md) — where `tests/`, `support/`, and `snapshots/` sit.
- [02 — Error Messages](02-error-messages.md) — exit-code matrix is unit-tested.
- Language-specific guides:
  - [`rust/cli-spec/06-testing.md`](../../languages/rust/cli-spec/06-testing.md) — `assert_cmd` + `insta` + `tempfile` + `nextest`.
  - [`python/cli-spec/typer-patterns.md`](../../languages/python/cli-spec/typer-patterns.md) — `pytest` + `typer.testing.CliRunner`.
  - [`bash/cli-spec/bash-cli-project-specs.md`](../../languages/bash/cli-spec/bash-cli-project-specs.md) — `bats-core`.

## References

- [Google Testing Blog — Small/Medium/Large tests](https://testing.googleblog.com/2010/12/test-sizes.html)
- [`assert_cmd`](https://docs.rs/assert_cmd/) · [`insta`](https://insta.rs/docs/) · [`trybuild`](https://docs.rs/trybuild/)
- [`pytest`](https://docs.pytest.org/) · [`typer.testing`](https://typer.tiangolo.com/tutorial/testing/)
- [`bats-core`](https://bats-core.readthedocs.io/)
