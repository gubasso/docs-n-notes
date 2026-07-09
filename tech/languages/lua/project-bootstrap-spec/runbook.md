# Runbook — bootstrap a new Lua project

The ordered, **once-per-project** Lua-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Lua
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the interpreter and tooling — see
  [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Pick the runtime.** Choose Lua 5.1/5.3/5.4 or LuaJIT, and pin it in the Nix devShell so local
   and CI use the same interpreter. → [00 — Toolchain & layout](./00-toolchain-and-layout.md),
   [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md). _Automate:_
   `bootstrap-nix`.

2. **Lay out the module tree.** Establish the `require`-addressable source tree (`src/` or the rock
   name) and, for a publishable module, an initial `<name>-dev-1.rockspec`. →
   [00 — Toolchain & layout](./00-toolchain-and-layout.md).

3. **Configure quality gates.** `.stylua.toml` (format), `.luacheckrc` (lint), and a `spec/` tree
   for `busted` tests; wire them into pre-commit. → [01 — Quality gates](./01-quality-gates.md).
   _Automate:_ `bootstrap-precommit`, `bootstrap-taskrunner`.

4. **Pick the implementation kind.** For a LuaRocks module, follow
   [`rock-library.md`](./rock-library.md); other kinds are followups.

5. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci`.

## Reference

- [00 — Toolchain & layout](./00-toolchain-and-layout.md) ·
  [01 — Quality gates](./01-quality-gates.md) ·
  [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [nix/02 — per-project devShell](../../../tools/nix/02-per-project-devshell.md)
