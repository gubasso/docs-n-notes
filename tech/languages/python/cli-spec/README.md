# Python CLI Spec

Python-specific conventions for building a CLI tool, primarily with **Typer** (which wraps **Click**) and **Pydantic** for validation.

For the language-agnostic principles, see [`tech/programming/cli-design/`](../../../programming/cli-design/). Every Python-specific rule here applies the general principles to the specifics of Python.

## Files

| File                                                           | Hook                                                                                                                  |
| -------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------- |
| [typer-patterns.md](typer-patterns.md)                         | Practical Typer/Click patterns: path options, Pydantic validators, multi-value parsing, RootModel-based custom types. |
| [parse-cli-options-examples.py](parse-cli-options-examples.py) | Runnable examples: Typer + Pydantic for validation callbacks, tag parsing, complex key=value parsing.                 |
| [config-precedence-python.md](config-precedence-python.md)     | Layered config-path resolution with `lru_cache` + `pydantic-settings`.                                                |

## Stack defaults

| Concern                 | Library                                  |
| ----------------------- | ---------------------------------------- |
| Argument parsing        | `typer` (built on `click`)               |
| Validation              | `pydantic` v2                            |
| Layered config          | `pydantic-settings`                      |
| Logging emission        | `structlog` (or `loguru` for simplicity) |
| User-UX terminal output | `rich`                                   |
| Interactive prompts     | `questionary` (or `rich.prompt`)         |
| Tests                   | `pytest` + `typer.testing.CliRunner`     |
| Snapshots               | `syrupy`                                 |
| Linting                 | `ruff`                                   |
| Formatting              | `ruff format`                            |
| Type checking           | `mypy` or `pyright`                      |

## TL;DR

- One file per subcommand under `cli/`; one handler per subcommand under `commands/`.
- General parse-shape → runtime-shape maps to **Typer parameters → Pydantic request models** in Python.
- Validation lives in `__post_init__` / Pydantic validators, not in handler bodies.
- Logging via `structlog` writes structured records to `${XDG_STATE_HOME:-~/.local/state}/<app>/<app>.log` by default.
- `pytest` with `-n auto`. Every subcommand has `tests/test_cmd_<name>.py`.

## See also

- [General — Architecture](../../../programming/cli-design/00-architecture.md)
- [General — Logging & Output](../../../programming/cli-design/01-logging-and-output.md)
- [General — Error Messages](../../../programming/cli-design/02-error-messages.md)
- [General — Config Precedence](../../../programming/cli-design/03-config-precedence.md)
- [General — Coding Style (Rust/Zig flavor, with Python translations)](../../../programming/cli-design/04-coding-style-rust-zig.md)
