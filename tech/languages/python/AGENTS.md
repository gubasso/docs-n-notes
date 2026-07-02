---
digest-of: tech/languages/python
last-synced: 2026-07-01
source-files:
  - django-code-review-guide.md
  - python.md
  - pydantic-mixins-with-enums.md
  - pydantic-validators.md
  - pytest-conftest-fixture.md
  - install-local-python-module-with-cli-access-in-a-virtual-environment.md
  - python-eve.md
  - python-flask.md
  - python-mongo.md
  - python-poetry.md
token-estimate: 560
---

# AGENTS

## Scope

Python language notes at the top level (outside `cli-spec/`). Includes a Django code-review guide,
general notes, Pydantic patterns, pytest fixtures, framework references, and packaging/environment
conventions.

## Key Points

- **Environment vs dependencies**: the Python runtime is provisioned by the project's Nix flake
  devShell (canonical per-project environment manager); Poetry manages dependencies inside it. Do
  not replace Poetry with Nix/poetry2nix by default. See
  `../../workflows/development-tools-workflow.md` and `../../tools/nix.md`.
- **Django review guide**: Django-specific review heuristics (N+1 queries, migrations, security,
  template injection).
- **General notes** (`python.md`): project environment/runtime, shell commands via subprocess, type
  hints (mypy cheat sheet), CLI libraries (docopt), rich/pprint, project layout, imports.
- **Pydantic**: Mixin patterns with enums, validator patterns (field/model validators).
- **Testing**: pytest conftest fixture patterns and organization.
- **Packaging**: local Python module with CLI access in a virtualenv; Poetry deps, lockfile export,
  container-deploy patterns.
- **Frameworks**: Eve, Flask, MongoDB integration notes.

## Source Map

| Topic                       | File                                                                      |
| --------------------------- | ------------------------------------------------------------------------- |
| Django review heuristics    | `django-code-review-guide.md`                                             |
| General Python notes        | `python.md`                                                               |
| Pydantic enum mixins        | `pydantic-mixins-with-enums.md`                                           |
| Pydantic validators         | `pydantic-validators.md`                                                  |
| pytest conftest/fixture     | `pytest-conftest-fixture.md`                                              |
| Local module + CLI in venv  | `install-local-python-module-with-cli-access-in-a-virtual-environment.md` |
| Poetry (deps + environment) | `python-poetry.md`                                                        |
| Flask, Eve, MongoDB         | `python-flask.md`, `python-eve.md`, `python-mongo.md`                     |
| CLI project spec            | `cli-spec/` (separate AGENTS.md)                                          |

## Maintenance Notes

- CLI-spec has its own AGENTS.md; this digest covers only the top-level Python files.
- Framework notes (Eve, Flask, MongoDB) are reference-link collections; load directly when relevant.
- Environment-manager guidance is cross-cutting; its home is
  `tech/workflows/development-tools-workflow.md` — the Python notes only cross-link it.
