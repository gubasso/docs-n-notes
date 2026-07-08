# 00 — Toolchain & layout

The Nix ecosystem choices for a fresh flake: how to scaffold it, how to structure `flake.nix`, how
to pin `nixpkgs`, and how to lay out packages / modules / overlays. This binding is about authoring
a **flake as the deliverable**; for language detail on the expression syntax and the output schema,
link to the [Nix language shelf](../README.md) — do not restate it here.

## Scaffold the flake

- Empty starting point: `nix flake init` (drops a minimal `flake.nix` in the current dir).
- From a template: `nix flake init -t <flake>#<name>` (e.g. a `flake-parts` or devShell template).

`bootstrap-nix` automates a starting flake. See [`02-flakes.md`](../02-flakes.md) for the minimal
`flake.nix` shape (`description`, `inputs`, `outputs`).

## `flake.nix` structure

A flake is one attribute set with three keys — `description`, `inputs`, and `outputs` (a function).
The [flake language reference](../02-flakes.md) owns the syntax; the bootstrap choice here is the
**outputs harness**:

- **`flake-utils`** — `eachDefaultSystem` generates per-system outputs with minimal ceremony. Good
  default for a small flake. See the `eachDefaultSystem` pattern in
  [`02-flakes.md`](../02-flakes.md).
- **`flake-parts`** — a module-system way to structure larger flakes; step up to it when the flake
  grows multiple packages, modules, and overlays. See
  [`05-tooling-gotchas-resources.md`](../05-tooling-gotchas-resources.md).

Always add `inputs.<x>.inputs.nixpkgs.follows = "nixpkgs"` to every input that carries its own
`nixpkgs`, to avoid a second copy.

## Pin `nixpkgs` + `flake.lock`

- Pin `inputs.nixpkgs.url` to a branch: `github:NixOS/nixpkgs/nixos-unstable` for a dev/tooling
  flake, or a release branch (`nixos-24.11`) when the flake targets machines.
- Run `nix flake lock` to generate `flake.lock`, and **commit it** — the lockfile is what makes
  builds reproducible. `nix flake update` bumps everything; `nix flake lock --update-input nixpkgs`
  bumps one.
- Remember: flakes only see **git-tracked** files, so `git add` new sources before they appear in a
  `src = ./.;` build (see the gotchas in
  [`05-tooling-gotchas-resources.md`](../05-tooling-gotchas-resources.md)).

## Layout

For a tiny flake, everything can live in `flake.nix`. As it grows, split outputs into files so the
top-level flake stays a readable index:

```text
flake.nix            # inputs + outputs wiring only
flake.lock           # committed pin
nix/                 # or split further:
  packages/          # one file per derivation
  modules/           # nixosModules / homeManagerModules
  overlays/          # overlay functions
```

For the shape of each output (`packages`, `devShells`, `nixosModules`, `overlays`, …) see the output
schema in [`03-flake-outputs.md`](../03-flake-outputs.md) and, for modules,
[`04-nixos-and-modules.md`](../04-nixos-and-modules.md). Bootstrap owns the _ordering_ (get an
evaluable, `nix flake check`-clean flake first); the language shelf owns the detailed _how_.

## Automation

`bootstrap-nix` lays down a starting flake and devShell. The steps above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
