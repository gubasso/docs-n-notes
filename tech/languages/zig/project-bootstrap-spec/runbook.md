# Runbook — bootstrap a new Zig project

The ordered, **once-per-project** Zig-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Zig
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the toolchain — see
  [nix/templates/zig](../../../tools/nix/templates/zig/). If you resolve the compiler with anyzig,
  see the [anyzig workflow](../anyzig-workflow.md).

## Steps

1. **Scaffold the project.** `zig init` in the project directory creates `build.zig`,
   `build.zig.zon`, and `src/`. With anyzig, pin the version on the first run: `zig <version> init`.
   → [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [anyzig workflow](../anyzig-workflow.md). _Automate:_ no dedicated cog skill yet; run `zig init`
   manually.

2. **Pin the Zig version.** Set `.minimum_zig_version` in `build.zig.zon` and host the matching
   toolchain in the Nix devShell so local and CI use the same compiler. Zig moves fast — this pin is
   load-bearing. → [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [nix/templates/zig](../../../tools/nix/templates/zig/).

3. **Configure quality gates.** Wire `zig fmt` and `zig build test` — Zig's formatter and test
   runner are built into the compiler, so there is little to install. →
   [01 — Quality gates](01-quality-gates.md). _Automate:_ `bootstrap-precommit`,
   `bootstrap-taskrunner`.

4. **Pick the implementation kind.** For a CLI executable, follow
   [`cli-project.md`](cli-project.md); for a reusable module, follow
   [`library-project.md`](library-project.md).

5. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci`.

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [anyzig workflow](../anyzig-workflow.md)
