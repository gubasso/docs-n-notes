# Bash

Bash notes and workflow references.

- [cli-spec](cli-spec/README.md) — Bash CLI conventions: layout, strict mode, modules, ShellCheck
  discipline, `bats-core` testing, install + XDG, distribution
- [project-bootstrap-spec](project-bootstrap-spec/README.md) — bootstrap a new Bash project:
  toolchain/layout, quality gates, and CLI implementation-kind (bash binding of
  [general project-bootstrap](../../programming/project-bootstrap/README.md))
- [release-workflow-spec](release-workflow-spec/README.md) — the Bash release & distribution shelf:
  tag → GitHub Release, git-cliff changelog, Makefile, `install.sh`, AUR, OBS (bash binding of
  [general release-workflow](../../programming/release-workflow/README.md))

Toolchain: the canonical per-project setup is a Nix devShell hosting `bash`, `shfmt`, `shellcheck`,
and `bats` — see [nix/02-per-project-devshell](../../tools/nix/02-per-project-devshell.md).
