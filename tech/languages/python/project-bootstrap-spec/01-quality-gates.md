# 01 — Quality gates

The Python concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters. All
config lives in `pyproject.toml`.

## Formatter + linter — `ruff`

`ruff` is the modern default: one fast tool that both formats and lints, replacing the older black +
flake8 + isort stack. Configure it under `[tool.ruff]` and enforce in CI:

```bash
ruff format --check
ruff check
```

If you inherit an older project, **black** (format), **flake8** (lint), and **isort** (imports) are
the stack `ruff` supersedes; keep one owner rather than running both.

## Typecheck — `mypy` / `pyright`

Add a static type checker and run it in CI. Pick one:

```bash
mypy src        # or:
pyright
```

Configure under `[tool.mypy]` in `pyproject.toml` (pyright reads `pyproject.toml` or
`pyrightconfig.json`). Prefer strict mode for new code.

## Tests — `pytest`

`pytest` is the default test runner; put tests under `tests/` and run against the installed package
(the src layout enforces this):

```bash
pytest
```

## Security — `pip-audit`

`pip-audit` is the Python tool behind the general security baseline: it fails on installed
dependencies with known advisories (PyPI Advisory Database / OSV).

```bash
pip-audit
```

Run it in CI so a vulnerable dependency cannot merge.

## Pre-commit wiring

Wire `ruff format --check`, `ruff check`, `mypy`/`pyright`, and `pytest` into the pre-commit hooks
from the general [04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so
failures surface locally in seconds. `bootstrap-precommit` automates the hook config.

## Publish-readiness (later phase)

Publish-grade checks (`uv build`, `twine check`, metadata completeness) belong to the release phase,
not bootstrap — see [`../release-workflow-spec/`](../release-workflow-spec/README.md). Bootstrap
only guarantees the project builds, formats, lints, typechecks, tests, and audits clean.
