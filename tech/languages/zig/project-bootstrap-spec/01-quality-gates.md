# 01 — Quality gates

The Zig concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

Zig's tooling is deliberately minimal: the formatter and the test runner ship **inside the
compiler**, so there is almost nothing to install and no third-party linter to wire up. Do not reach
for external Zig linters — the canonical gates below are the built-ins.

## Formatter — `zig fmt`

`zig fmt` is the non-negotiable, canonical formatter; it has no configuration knobs. Enforce in CI
with a check that fails when files are not formatted:

```bash
zig fmt --check .
```

## Tests — `zig build test`

Zig's test runner is built into the compiler. `test { ... }` blocks live alongside the code they
cover; the `test` step declared in `build.zig` collects and runs them:

```bash
zig build test
```

`zig test <file>.zig` runs a single file's tests directly. There is no separate test framework to
add.

## Compile-time safety and checks

Much of what other ecosystems delegate to a linter, Zig enforces at compile time: unused locals and
unused parameters are errors, and the Debug/ReleaseSafe build modes insert runtime safety checks
(bounds, overflow, null-unwrap). Building cleanly is itself a gate — treat `zig build` warnings and
errors as blocking. There is no widely-adopted third-party linter to add on top; the compiler is the
linter.

## Pre-commit wiring

Wire `zig fmt --check .` and `zig build test` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds. A task runner recipe (`bootstrap-taskrunner`) that fronts these as one command
keeps local and CI invocations identical.

## Security baseline

Zig has no `cargo-audit` equivalent. The general
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) still applies —
secrets hygiene, pinned dependency hashes in `build.zig.zon` (every dependency carries a content
hash, so tampering is detectable), and the OpenSSF Scorecard checklist.
