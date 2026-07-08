# Runbook — bootstrap a new C project

The ordered, **once-per-project** C-specific steps, overlaying the general spine. Each step links to
the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the C
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the toolchain — see
  [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Lay out sources and pick a build system.** Create `src/` and `include/<project>/`, then choose
   CMake or Meson and add its top-level build file. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Pin the toolchain.** Select the compiler (gcc or clang) and C standard (e.g. `c11`/`c17`), and
   wire both into the Nix devShell so local and CI use the same versions. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md).

3. **Configure quality gates.** Add `.clang-format` and `.clang-tidy`, a cppcheck invocation, an
   ASan/UBSan build variant for tests/CI, and a unit-test framework (Unity, CMocka, or Criterion). →
   [01 — Quality gates](01-quality-gates.md). _Automate:_ `bootstrap-editorconfig` (formatter
   alignment), `bootstrap-precommit` (hook wiring), `bootstrap-taskrunner` (build/test/format
   recipes).

4. **Pick the implementation kind.** For a CLI, follow [`cli-project.md`](cli-project.md); for a
   shared/static library, follow [`library-project.md`](library-project.md).

5. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci` (first CI workflow), `bootstrap-nix`
   (devShell + `.envrc`).

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md)
