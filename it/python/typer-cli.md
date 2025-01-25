# Python Typer CLI (click)

path cli option example

```python
    config_path: Annotated[
        Optional[Path],
        typer.Option(
            exists=True,
            file_okay=False,
            dir_okay=True,
            readable=True,
            resolve_path=True,
            help="Path to the configuration directory that holds the configuration files.",
        ),
    ] = None,
    some_dir: Optional[Path] = typer.Option(
        None,
        help="Dir to save something",
    ),
    list_of_dirs: Optional[List[Path]] = typer.Option(
        None,
        help="List of dirs",
    ),
```
