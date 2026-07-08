# 01 — Quality gates

The Bash concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

## Formatter — `shfmt`

`shfmt` is the standard Bash formatter. Pick indentation and enforce in CI with the check flag (`-d`
prints a diff and exits non-zero when reformatting is needed):

```bash
shfmt -d -i 2 -ci -sr .
```

- `-i 2` — two-space indent (choose your width once).
- `-ci` — indent switch-case bodies.
- `-sr` — space after redirect operators.

## Linter — `shellcheck`

`shellcheck` is the non-negotiable linter. Run it over every script and treat warnings as errors so
lint failures block the build:

```bash
shellcheck -S style bin/* lib/**/*.sh tests/*.bats
```

- `-S style` — surface style-level findings, not just errors and warnings.
- Silence a specific finding only with an inline `# shellcheck disable=SCxxxx` plus a comment saying
  why — never blanket-disable.

Bash has no built-in security scanner, so ShellCheck is also the security gate: it flags the
injection-prone patterns (unquoted expansion, `eval` on input, word-splitting) that the general
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) calls for.

## Tests — `bats-core`

Use `bats-core` (Bash Automated Testing System) for tests; one `.bats` file per subcommand or unit:

```bash
bats tests/
```

Keep tests hermetic (no network, temp dirs via `mktemp`) so they run in CI and pre-commit.

## Pre-commit wiring

Wire `shfmt -d`, `shellcheck`, and `bats` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds. Expose the same three as task-runner recipes (`fmt`, `lint`, `test`) so CI and
local use one command each.

## Distribution-readiness (later phase)

Shipping the scripts (an `install.sh`, AUR/OBS packaging, changelog) belongs to the release phase,
not bootstrap — see [`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap
only guarantees the scripts format, lint, and test clean.
