# 00 — Toolchain & layout

The C ecosystem choices for a fresh project: how to lay out sources, which build system and compiler
to pick, which C standard to target, and how the Nix devShell hosts it all.

## Source & include layout

C has no cargo-style scaffolder, so establish the tree by hand:

```text
project/
├── include/<project>/   # public headers — the API surface consumers include
├── src/                 # .c implementation files (and private .h)
├── tests/               # unit tests
└── <build-file>         # CMakeLists.txt or meson.build
```

Keep the public header namespace under `include/<project>/` so downstream code writes
`#include <project/foo.h>`. Private headers stay next to their `.c` in `src/`.

## Build system

Pick one mainstream, well-supported generator — do not hand-roll Makefiles for anything non-trivial:

- **CMake** — the de-facto default; broadest tooling and IDE support. Target C11/C17 via
  `set(CMAKE_C_STANDARD 17)` and `set(CMAKE_C_STANDARD_REQUIRED ON)`.
- **Meson** — simpler syntax, fast Ninja backend; set the standard with
  `default_options: ['c_std=c17']`.

Both integrate cleanly with the quality gates in [01 — Quality gates](./01-quality-gates.md) and
export a `compile_commands.json` that clang-tidy and clangd consume.

## Compiler & C standard

- **Compiler:** gcc or clang; keep the build compiler-agnostic and test with both in CI when
  feasible. clang is required for clang-tidy's richest checks and for the sanitizers.
- **Standard:** pick an explicit standard (`c11` or `c17` for most projects; `c99` only for legacy
  targets) and enforce it in the build file rather than relying on the compiler default.
- Build with `-Wall -Wextra -Wpedantic` from day one; add `-Werror` in CI.

## Toolchain hosting + Nix

Host the compiler, build system, and tooling in a Nix devShell so local and CI share one toolchain
and the "works on my machine" gap closes before any code is written. The per-project setup is owned
by [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md); this binding only
declares _which_ tools belong in the shell (gcc/clang, cmake/meson, ninja, clang-format, clang-tidy,
cppcheck).

## Automation

Deterministic scaffolding is delegated to cog helpers — `bootstrap-nix` for the devShell,
`bootstrap-taskrunner` for build/test recipes. The steps above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
