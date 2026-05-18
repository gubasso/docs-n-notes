# Config Precedence — Python Pattern

> Prerequisite: [General — Config Precedence](../../../programming/cli-design/03-config-precedence.md) for the `CLI > env > project > user > defaults` rule. This file is a working Python implementation of the fallback chain.

A compact Python pattern for resolving a config-path from CLI flag → env var → user XDG path → built-in default. Caches the result per process.

## Pattern

```python
from functools import lru_cache
from pathlib import Path
from typing import Optional
import logging
import os

logger = logging.getLogger(__name__)

DEFAULT_USER_CONFIG_PATH = Path("~/.config/myapp").expanduser()


@lru_cache(maxsize=1)
def get_config_path(cli_config_path: Optional[Path] = None) -> Path:
    env_config_path_env: Optional[str] = os.getenv("CONFIG_PATH")
    env_config_path: Optional[Path] = (
        Path(env_config_path_env) if env_config_path_env else None
    )

    possible_paths = [
        cli_config_path,
        env_config_path,
        DEFAULT_USER_CONFIG_PATH,
    ]

    for path in possible_paths:
        if path and path.expanduser().is_dir():
            logger.debug(f"Using configuration path: {path}")
            return path.expanduser()

    error_message = (
        "No configuration path found. Checked the following locations:\n"
        f"1. CLI input: {cli_config_path}\n"
        f"2. Environment variable 'CONFIG_PATH': {env_config_path}\n"
        f"3. User configuration directory: {DEFAULT_USER_CONFIG_PATH}\n"
    )
    logger.error(error_message)
    raise FileNotFoundError(error_message)
```

## Why this shape

- **`lru_cache(maxsize=1)`**: resolve once per process. `Config` is immutable; recomputing the path is wasteful.
- **Explicit fallback ladder**: the order is the precedence rule from the general principle. The first match wins.
- **Error message names every location checked**: the user (or LLM agent) reading the error can debug without source-diving.
- **`expanduser()` deferred**: keeps the comparison fast; only expand the winning path.

## For larger projects: `pydantic-settings`

When you have more than ~3 settings, switch to [`pydantic-settings`](https://docs.pydantic.dev/latest/concepts/pydantic_settings/), which gives you layered loading + validation + automatic env-var binding in one class.

```python
from pydantic_settings import BaseSettings, SettingsConfigDict

class Config(BaseSettings):
    timeout_secs: int = 30
    editor: str = "vi"

    model_config = SettingsConfigDict(
        env_prefix="MYAPP_",
        env_nested_delimiter="__",
        toml_file=("~/.config/myapp/config.toml", "./.myapp/config.toml"),
    )
```

Source precedence in `pydantic-settings` (high → low): init kwargs > env vars > dotenv > file > secrets > defaults — matches the general principle if you pass CLI values as init kwargs.

## See also

- [General — Config Precedence](../../../programming/cli-design/03-config-precedence.md)
- [typer-patterns.md](typer-patterns.md) — using these patterns with Typer commands.
