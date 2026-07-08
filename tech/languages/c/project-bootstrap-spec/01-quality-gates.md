# 01 — Quality gates

The C concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters. C has
no single bundled toolbox, so wire each gate explicitly.

## Formatter — `clang-format`

`clang-format` is the standard formatter. Commit a `.clang-format` (start from a named base style,
e.g. `BasedOnStyle: LLVM`) and enforce in CI:

```bash
clang-format --dry-run --Werror $(git ls-files '*.c' '*.h')
```

## Linter / static analysis — `clang-tidy` + `cppcheck`

Use both; they catch different classes of defect:

- `clang-tidy` — clang-based lint and modernization checks; reads `compile_commands.json` and a
  committed `.clang-tidy` for the enabled check list.

  ```bash
  clang-tidy -p build $(git ls-files '*.c')
  ```

- `cppcheck` — independent static analyzer strong on out-of-bounds, leaks, and undefined behavior.

  ```bash
  cppcheck --enable=warning,style,performance --error-exitcode=1 src include
  ```

## Sanitizers — ASan / UBSan

Build a dedicated test/CI variant with AddressSanitizer and UndefinedBehaviorSanitizer so memory and
UB bugs fail the test run rather than shipping:

```bash
cc -fsanitize=address,undefined -fno-omit-frame-pointer -g ...
```

In CMake, gate this behind an option (e.g. `-DENABLE_SANITIZERS=ON`); in Meson use
`-Db_sanitize=address,undefined`. Run the full test suite under sanitizers in CI.

## Unit-test framework

Pick one lightweight framework and wire it into the build system's test runner (CTest for CMake,
`meson test` for Meson):

- **Unity** — minimal, single-file, ideal for embedded/small projects.
- **CMocka** — supports mocking and structured fixtures.
- **Criterion** — modern, auto-registering tests with parallel runs.

## Pre-commit wiring

Wire `clang-format --dry-run --Werror` and `clang-tidy`/`cppcheck` into the pre-commit hooks from
the general [04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so
failures surface locally in seconds. `bootstrap-precommit` automates the hook wiring.
