---
digest-of: tech/languages/bash/cli-spec
last-synced: 2026-05-27
source-files:
  - README.md
  - bash-cli-project-specs.md
token-estimate: 800
---

# AGENTS

## Scope

Bash-specific CLI conventions: directory layout, strict mode, module organization, testing, linting,
installation, and distribution.

## Key Points

- **Entry point**: `bin/<name>` is a thin shim resolving symlinks, sourcing `lib/helpers.sh`,
  `lib/loader.sh`, `lib/core.sh`, then calling `mycli::main "$@"`.
- **Strict mode**: `set -euo pipefail` + `shopt -s inherit_errexit`. Know caveats:
  `local var=$(...)` masks exit, pipefail can fail on SIGPIPE, never set `IFS=$'\n\t'` globally.
- **Module layout**: One public function per file. `lib/commands/cmd_<n>.sh` defines
  `mycli::cmd::<n>`. `lib/functions/fn_<n>.sh` defines `mycli::fn::<n>`. Private helpers prefixed
  `__`.
- **Lazy loading**: `lib/loader.sh` sources commands on dispatch, keeping startup O(1).
- **ShellCheck**: `.shellcheckrc` with `external-sources=true`, `source-path=SCRIPTDIR`. Every
  `source` gets an explicit `# shellcheck source=` directive. Disables require justification
  comments.
- **Errors/signals**: `mktemp -d || exit 1` + `trap ... EXIT INT TERM`. SIGINT=130, SIGTERM=143.
  `printf` over `echo`.
- **Testing**: `bats-core` with `bats-support`, `bats-assert`, `bats-file` as submodules. One test
  file per subcommand.
- **Formatting**: `shfmt -i 2 -ci -bn -s`. All checks via pre-commit.
- **Install/XDG**: `install.sh` honors `PREFIX` (system) and XDG (user). Bash completions, man pages
  via scdoc.
- **Non-negotiables**: Namespaced functions, XDG-aware installer, trap cleanup, agent-facing surface
  (`--help`, `--json`, `doctor`, exit codes).

## Source Map

| Topic                                                         | File                        |
| ------------------------------------------------------------- | --------------------------- |
| Overview and TL;DR                                            | `README.md`                 |
| Full spec: layout, strict mode, modules, testing, install, CI | `bash-cli-project-specs.md` |

## Maintenance Notes

- Agent-facing surface rules (output-as-prompt, error shape) are in the general
  `cli-design/05-designing-for-llm-agents.md`, not duplicated here.
- Regenerate when bash ecosystem tooling changes (bats major version, shellcheck rules).
