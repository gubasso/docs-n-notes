# Programming Patterns Paradigms

Prioritize loadings a variable cli > env > default:

```python
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
