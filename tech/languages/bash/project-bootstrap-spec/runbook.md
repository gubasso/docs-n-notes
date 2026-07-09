# Runbook — bootstrap a new Bash project

The ordered, **once-per-project** Bash-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Bash
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the toolchain (`bash`, `shfmt`, `shellcheck`, `bats`) —
  see [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Lay down the script layout.** Create `bin/<name>` (thin shim) and a `lib/` tree; set the
   shebang and `set -euo pipefail`. → [00 — Toolchain & layout](./00-toolchain-and-layout.md).

2. **Host the toolchain in the devShell.** Add `bash`, `shfmt`, `shellcheck`, and `bats` to the Nix
   devShell so local and CI share one set of versions. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md),
   [nix/02-per-project-devshell](../../../tools/nix/02-per-project-devshell.md). _Automate:_
   `bootstrap-nix`.

3. **Configure quality gates.** `shfmt` for formatting, `shellcheck` for linting, and `bats-core`
   for tests; wire all three into pre-commit and the task runner. →
   [01 — Quality gates](./01-quality-gates.md). _Automate:_ `bootstrap-precommit`,
   `bootstrap-taskrunner`.

4. **Pick the implementation kind.** For a CLI tool, follow [`cli-project.md`](./cli-project.md);
   other kinds are followups.

5. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci`.

6. **When ready to release,** hand off to
   [`../release-workflow-spec/runbook.md`](../release-workflow-spec/runbook.md) — the later Bash
   release phase (tag, git-cliff changelog, Makefile, `install.sh`, AUR, OBS).

## Reference

- [00 — Toolchain & layout](./00-toolchain-and-layout.md) ·
  [01 — Quality gates](./01-quality-gates.md) ·
  [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [`../cli-spec/`](../cli-spec/README.md)
