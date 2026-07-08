# C — bootstrap a new project (spec/binding)

The C binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete C tooling — source/include layout, a build
system (CMake or Meson), compiler and C-standard choice, and the clang-format / clang-tidy /
cppcheck / sanitizer quality gates — and links to C implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the C specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
1. Follow this [`runbook.md`](runbook.md) for the C-specific overlay steps.
1. Jump to your implementation-kind file (e.g. [`cli-project.md`](cli-project.md) or
   [`library-project.md`](library-project.md)).

## Index

| # | Chapter                                          | One-line hook                                                                     |
| - | ------------------------------------------------ | --------------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](00-toolchain-and-layout.md) | `src/`/`include/` layout, CMake/Meson, gcc/clang, C standard, Nix devShell.       |
| 1 | [Quality gates](01-quality-gates.md)             | clang-format, clang-tidy/cppcheck, ASan/UBSan, a unit-test framework, pre-commit. |

## Implementation kinds

- [`cli-project.md`](cli-project.md) — C CLI: the bootstrap-time ordering for argument parsing,
  entry point, and exit codes.
- [`library-project.md`](library-project.md) — C library: a shared/static library with a public
  header API, install/export rules, and ABI hygiene.

`daemon-project.md` and other kinds are followups; add them when you bootstrap those kinds.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md) — how the C
  toolchain is hosted in a reproducible per-project shell.
