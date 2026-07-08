# Nix flake project — implementation-kind additions

What the **standard flake** kind adds on top of the general recipe and the Nix binding: a flake that
exposes buildable `packages` and one or more `devShells`, and optionally reusable `nixosModules` /
`homeManagerModules`. This is the default shape of a Nix codebase-as-deliverable. This file owns
only the **bootstrap-time ordering**; the detailed _how_ of each output lives in the
[Nix language shelf](../README.md) and is not restated here.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Nix
  [binding runbook](runbook.md) are done — an evaluable, gated flake exists with `nixpkgs` pinned
  and `flake.lock` committed.

## Add these, in this order

Layer these outputs on the evaluable flake in order — each links to the schema chapter that details
it:

1. **A `packages.default` derivation.** The thing this flake builds — `stdenv.mkDerivation` or an
   ecosystem builder (`buildRustPackage`, `buildGoModule`, `buildNpmPackage`). → output schema in
   [`03-flake-outputs.md`](../03-flake-outputs.md).
2. **A `devShells.default`.** A `mkShell` giving contributors the tools to hack on this flake
   (formatter, `statix`, `deadnix`, `nix`). For _consuming_ a devShell to host another language, see
   the general
   [03 — Local dev environment](../../../programming/project-bootstrap/03-local-dev-environment.md)
   chapter instead — here the shell is for developing the flake itself.
3. **`apps.default` (if it ships an executable).** A `{ type; program; }` pointing at the built
   binary so `nix run` works. → [`03-flake-outputs.md`](../03-flake-outputs.md).
4. **`checks` for the quality gates.** Expose format/lint/dead-code as `checks.<sys>.*` so
   `nix flake check` gates them. → [01 — Quality gates](01-quality-gates.md).
5. **Optional `nixosModules` / `homeManagerModules`.** If the flake ships reusable config, author a
   module with `options`/`config`. → [`04-nixos-and-modules.md`](../04-nixos-and-modules.md).

## Other flake kinds (followups)

- **Overlay-only** — a flake whose deliverable is `overlays.default` extending nixpkgs, with no
  top-level packages. Add `overlay-project.md` when you bootstrap one.
- **Module-only** — a flake shipping just `nixosModules` / `homeManagerModules` (no packages). Add
  `module-project.md` when you bootstrap one.

Both reuse this binding's toolchain and quality-gate chapters; they differ only in which outputs are
primary.
