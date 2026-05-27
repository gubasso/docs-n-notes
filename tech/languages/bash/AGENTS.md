---
digest-of: tech/languages/bash
last-synced: 2026-05-27
source-files:
  - code-review-guide.md
token-estimate: 400
---

# AGENTS

## Scope

Bash language notes at the top level (outside `cli-spec/`). Currently contains the code-review guide
for Bash scripts.

## Key Points

### Bash Review Heuristics

- **Strict mode**: Missing `set -euo pipefail` -> `[blocking]`.
- **Quoting**: Unquoted `$var` in non-numeric context -> `[blocking]` (word-splitting + glob bug).
- **Command injection**: `eval "$user_input"`, `bash -c "$cmd"`, `ssh host "ls $dir"` ->
  `[blocking]`.
- **Process management**: Background job without `wait` or trap-cleanup -> `[important]`.
- **Test brackets**: `[[ ]]` preferred over `[ ]` in bash; `-a`/`-o` deprecated.
- **Common bugs**: `for f in $(ls)` -> `[blocking]`; `cd $dir` without `|| exit` -> `[important]`;
  unchecked pipeline without pipefail.

## Source Map

| Topic                                                                          | File                             |
| ------------------------------------------------------------------------------ | -------------------------------- |
| Bash-specific review heuristics (strict mode, quoting, injection, common bugs) | `code-review-guide.md`           |
| CLI project spec (layout, modules, testing)                                    | `cli-spec/` (separate AGENTS.md) |

## Maintenance Notes

- The code-review guide is loaded on demand by the review-code-deep skill when `.sh`/`.bash` files
  are in the diff.
- CLI-spec has its own AGENTS.md; this digest covers only the top-level bash directory.
