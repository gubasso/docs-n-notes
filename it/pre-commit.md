# pre-commit hooks


To run in just a subdir or selected files...

```yaml
---
files: ^my-subdif/
default_install_hook_types: [pre-commit, commit-msg]

repos:
  # Pre-commit hooks provided by the pre-commit project
  - repo: https://github.com/pre-commit/pre-commit-hooks
    rev: v4.6.0
    hooks:
      # Check if Python files are syntactically valid
```
