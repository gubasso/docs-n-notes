---
digest-of: tech/languages/python/cli-spec
last-synced: 2026-05-27
source-files:
  - README.md
  - typer-patterns.md
  - config-precedence-python.md
  - parse-cli-options-examples.py
token-estimate: 900
---

# AGENTS

## Scope

Python-specific CLI conventions using Typer/Click and Pydantic. Covers stack defaults, typed CLI
patterns, layered config, and validation callbacks.

## Key Points

- **Stack**: Typer (parsing), Pydantic v2 (validation), pydantic-settings (layered config),
  structlog/loguru (logging), rich (UX output), questionary (prompts), pytest + syrupy (testing),
  ruff (lint+format).
- **Parse-shape to runtime-shape**: Typer parameters map to Pydantic request models. Validation in
  `__post_init__`/validators, not handler bodies.
- **Config precedence**: Two patterns: (1) manual 5-layer loader with `lru_cache`, `platformdirs`,
  provenance dict; (2) `pydantic-settings` with `settings_customise_sources` for larger configs.
- **Provenance**: Errors must name the source layer (`user-file:/path`, `env:MYAPP_X`,
  `cli-flag:--x`).
- **Typed CLI options**: Path validation at parse time (`exists=True`, `resolve_path=True`),
  Pydantic `RootModel` for custom types, `callback=` for email/tag validation.
- **Key=value parsing**: `extract_cli_server_details` pattern for complex multi-field CLI entries.
- **Testing**: `pytest -n auto`, one `tests/test_cmd_<name>.py` per subcommand,
  `typer.testing.CliRunner`.

## Source Map

| Topic                                    | File                            |
| ---------------------------------------- | ------------------------------- |
| Stack defaults, TL;DR                    | `README.md`                     |
| Typer patterns, Pydantic validators      | `typer-patterns.md`             |
| 5-layer config loader, pydantic-settings | `config-precedence-python.md`   |
| Runnable validation examples             | `parse-cli-options-examples.py` |

## Maintenance Notes

- The `.py` file contains runnable examples, not documentation prose.
- Regenerate when Typer or Pydantic major versions change.
