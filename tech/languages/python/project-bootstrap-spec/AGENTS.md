---
digest-of: tech/languages/python/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
  - library-project.md
token-estimate: 900
---

# AGENTS

## Scope

Python binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project
Python setup that takes an empty repo to a scaffolded, gated project ready for feature work. It
**overlays** the general spine (repo, license, governance, dev env, CI, security) and never restates
it; it owns only the Python ecosystem choices and the two implementation-kind orderings (CLI,
library). Publishing is out of scope — it hands off to `../release-workflow-spec/`.

## Key Points

- **Manager:** `uv` is the modern default — one tool for interpreter, virtualenv (`.venv`), lockfile
  (`uv.lock`), and deps. Scaffold `uv init <name>` (app) or `uv init --package <name>`
  (distributable, adds build backend + `src/`). Alternatives, pick one owner: Poetry, PDM,
  pip-tools.
- **Manifest:** `pyproject.toml` (PEP 621). Bootstrap sets only `name`, `version`,
  `requires-python`, `description`, and a `[build-system]` backend (`hatchling` or `uv_build`).
  Publish-grade metadata (`license`, `authors`, `readme`, `urls`, `classifiers`, `keywords`) is
  deferred to the release phase — do not duplicate that gate here.
- **Layout:** src layout — importable package under `src/<name>/`, `tests/` outside `src/` so tests
  run against the installed package.
- **Interpreter pin:** `.python-version` (single line) pins one interpreter; `uv` reads it to manage
  `.venv` (`uv run <cmd>`). A Nix devShell provisions the interpreter + `uv` so local and CI share
  one toolchain (`nix/02-per-project-devshell`).
- **Quality gates (all in `pyproject.toml`):** `ruff` (format + lint, supersedes black + flake8 +
  isort), `mypy`/`pyright` (typecheck, strict for new code), `pytest` (tests under `tests/`),
  `pip-audit` (security baseline, PyPI Advisory DB / OSV). Wire all into pre-commit so failures
  surface locally.
- **CLI kind:** console-script entry under `[project.scripts]`; arg-parsing via `argparse` (stdlib)
  or `click`/`typer`; consistent error type + non-zero exit codes; stdlib `logging` (human on
  stdout, logs on stderr); config precedence flags > env > file, validated early (e.g. `pydantic`).
- **Library kind:** public API via `__all__` + private internals; `py.typed` marker (PEP 561); test
  the installed package (src layout enforces it); a docs skeleton (`mkdocs`/`sphinx`) if the API is
  non-trivial.
- **Automation:** `bootstrap-nix` provisions the devShell; `bootstrap-precommit` wires the hooks.
  The SoT-vs-cog contract lives in general `07-automation-with-cog.md` — the runbook owns the
  _what_, cog the _how_.

## Source Map

| Topic                                                            | File                         |
| ---------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related    | `README.md`                  |
| Ordered Python overlay steps (the _what_/_in what order_)        | `runbook.md`                 |
| `uv`, `pyproject.toml` PEP 621, src layout, version pin + Nix    | `00-toolchain-and-layout.md` |
| `ruff` / `mypy`·`pyright` / `pytest` / `pip-audit` + pre-commit  | `01-quality-gates.md`        |
| CLI bootstrap-time ordering (entry point, args, logging, config) | `cli-project.md`             |
| Library/PyPI bootstrap-time ordering (API, `py.typed`, docs)     | `library-project.md`         |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Release handoff (PyPI Trusted
  Publishing): `../release-workflow-spec/`. Detailed CLI structure: `../cli-spec/`.
- `web-service.md` is a declared followup kind; add it (and refresh `source-files`) when it lands.
- The Python packaging landscape (`uv`, `ruff`) moves fast — re-verify the default-tool choices
  against upstream on a cadence when regenerating.
- No conflicts among the current source files.
