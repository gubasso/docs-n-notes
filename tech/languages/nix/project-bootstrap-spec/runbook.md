# Runbook — bootstrap a new Nix project

The ordered, **once-per-project** Nix-specific steps for authoring a flake as the deliverable,
overlaying the general spine. Each step links to the chapter that explains the _why_; this page is
only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Nix
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- Nix is installed with flakes enabled — see [`tech/tools/nix`](../../../tools/nix/README.md).
- Flake syntax is familiar; if not, skim [`02-flakes.md`](../02-flakes.md) and
  [`03-flake-outputs.md`](../03-flake-outputs.md) in the Nix language shelf.

## Steps

1. **Scaffold the flake.** `nix flake init` (or `nix flake init -t <template>`) to drop a
   `flake.nix`. → [00 — Toolchain & layout](00-toolchain-and-layout.md). _Automate:_ `bootstrap-nix`
   lays down a starting flake.

2. **Choose the outputs harness.** `flake-utils` (`eachDefaultSystem`) for a small flake, or
   `flake-parts` for a larger, modular one. → [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [`02-flakes.md`](../02-flakes.md).

3. **Pin `nixpkgs` and commit `flake.lock`.** Pin `inputs.nixpkgs` to a branch, run
   `nix flake lock`, and commit the lockfile so builds are reproducible. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

4. **Lay out packages / modules / overlays.** Split `flake.nix` from `nix/` (or `packages/`,
   `modules/`, `overlays/`) so outputs stay readable. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md).

5. **Configure quality gates.** Pick a formatter (`nixpkgs-fmt` or `alejandra`), add `statix` +
   `deadnix`, expose `checks` so `nix flake check` gates them, and wire git hooks via
   `git-hooks.nix`. → [01 — Quality gates](01-quality-gates.md).

6. **Pick the implementation kind.** For the standard packages+devShells flake, follow
   [`flake-project.md`](flake-project.md); overlay-only and module-only kinds are followups.

7. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. CI runs `nix flake check` as its gate.

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [Nix language shelf](../README.md) · [`tech/tools/nix`](../../../tools/nix/README.md)
