# Runbook — bootstrap a new Python project

The ordered, **once-per-project** Python-specific steps, overlaying the general spine. Each step
links to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Python
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the interpreter and `uv` — see
  [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Scaffold the project.** `uv init <name>` (add `--package` / `--lib` for a distributable
   package). This lays down `pyproject.toml` (PEP 621) and a `.python-version`. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Adopt the src layout and pin Python.** Move the package under `src/`, and let
   `.python-version` + the Nix devShell pin one interpreter for local and CI. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md),
   [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md).

3. **Configure quality gates.** `ruff` (format + lint), `mypy`/`pyright` (typecheck), `pytest`
   (tests), and `pip-audit` for the security baseline — all configured in `pyproject.toml`. →
   [01 — Quality gates](./01-quality-gates.md).

4. **Wire pre-commit.** Add the ruff/mypy/pytest hooks so failures surface locally. →
   [01 — Quality gates](./01-quality-gates.md). _Automate:_ `bootstrap-precommit`.

5. **Pick the implementation kind.** For a CLI, follow [`cli-project.md`](./cli-project.md); for a
   distributable package, follow [`library-project.md`](./library-project.md).

6. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done.

7. **When ready to release,** hand off to
   [`../release-workflow-spec/runbook.md`](../release-workflow-spec/runbook.md) — the later Python
   release phase (build, PyPI Trusted Publishing).

## Reference

- [00 — Toolchain & layout](./00-toolchain-and-layout.md) ·
  [01 — Quality gates](./01-quality-gates.md) ·
  [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [`../release-workflow-spec/`](../release-workflow-spec/README.md)
