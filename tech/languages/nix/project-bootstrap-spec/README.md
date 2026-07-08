# Nix — bootstrap a new project (spec/binding)

The Nix binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe to authoring **a Nix codebase itself** — a flake that
provides packages, devShells, and (optionally) NixOS / Home Manager modules — with concrete Nix
tooling: `nix flake init`, nixpkgs pinning, and the format/lint/`nix flake check` quality gates. It
links to Nix implementation-kinds.

> **Scope:** here the flake **is the deliverable**. This is not about using a devShell to host
> another language — that is the general
> [03 — Local dev environment](../../../programming/project-bootstrap/03-local-dev-environment.md)
> chapter and [`tech/tools/nix`](../../../tools/nix/README.md). This binding is for when the Nix
> code is the product.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Nix specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
1. Skim the [Nix language shelf](../README.md) if flake syntax is unfamiliar — this binding links to
   it for language detail rather than restating it.
1. Follow this [`runbook.md`](runbook.md) for the Nix-specific overlay steps.
1. Jump to your implementation-kind file (e.g. [`flake-project.md`](flake-project.md)).

## Index

| # | Chapter                                          | One-line hook                                                                |
| - | ------------------------------------------------ | ---------------------------------------------------------------------------- |
| 0 | [Toolchain & layout](00-toolchain-and-layout.md) | `nix flake init`, `flake.nix` inputs/outputs, layout, pin nixpkgs + `.lock`. |
| 1 | [Quality gates](01-quality-gates.md)             | `nixpkgs-fmt`/`alejandra`, `statix` + `deadnix`, `nix flake check`, hooks.   |

## Implementation kinds

- [`flake-project.md`](flake-project.md) — the standard shape: a flake exposing `packages` +
  `devShells`, optionally `nixosModules` / `homeManagerModules`.

`overlay-project.md` (overlay-only) and `module-project.md` (module-only) are followups; add them
when you bootstrap those kinds.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [Nix language shelf](../README.md) — the flake / expression-language syntax reference this binding
  links to for language detail.
- [`tech/tools/nix`](../../../tools/nix/README.md) — Nix-as-a-tool: installing, per-project
  devShells for _other_ languages, project migration, templates.
