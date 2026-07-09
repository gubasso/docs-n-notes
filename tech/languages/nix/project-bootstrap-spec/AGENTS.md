---
digest-of: tech/languages/nix/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - flake-project.md
token-estimate: 850
---

# AGENTS

## Scope

Nix binding of the general `tech/programming/project-bootstrap/` shelf, for authoring **a Nix
codebase itself** — a flake that provides `packages`, `devShells`, and optionally NixOS / Home
Manager modules, where the flake **is the deliverable**. It **overlays** the general spine (repo,
license, governance, dev env, CI, security) and never restates it; it owns only the Nix ecosystem
choices and the flake implementation kind. Not for using a devShell to host another language — that
is general `03-local-dev-environment.md` and `tech/tools/nix`.

## Key Points

- **Scaffold:** `nix flake init` drops a minimal `flake.nix`; `nix flake init -t <flake>#<name>`
  starts from a template. `bootstrap-nix` automates a starting flake + devShell.
- **`flake.nix` shape:** one attribute set with `description`, `inputs`, `outputs` (a function). The
  bootstrap choice is the **outputs harness** — `flake-utils` (`eachDefaultSystem`, minimal
  ceremony, small flakes) vs `flake-parts` (module-system structure, step up as the flake grows
  multiple packages/modules/overlays). Add `inputs.<x>.inputs.nixpkgs.follows = "nixpkgs"` on every
  input carrying its own nixpkgs.
- **Pin + lock:** pin `inputs.nixpkgs.url` to a branch (`nixos-unstable` for dev/tooling flakes, a
  release branch like `nixos-24.11` when targeting machines), run `nix flake lock`, and **commit
  `flake.lock`** — the lockfile is what makes builds reproducible. `nix flake update` bumps all;
  `--update-input nixpkgs` bumps one. Flakes only see **git-tracked** files, so `git add` sources
  before a `src = ./.;` build.
- **Layout:** tiny flake lives entirely in `flake.nix`; as it grows, split outputs into `nix/`
  (`packages/` one file per derivation, `modules/`, `overlays/`) so the top-level flake stays a
  readable index. Bootstrap owns the ordering (get an evaluable, `nix flake check`-clean flake
  first).
- **Quality gates:** pick one canonical formatter — `nixpkgs-fmt` (conservative default) or
  `alejandra` (opinionated, faster) — exposed as `formatter.<sys>` so `nix fmt` uses it
  (`treefmt-nix` for multi-language repos); `statix` (Nix anti-patterns, `statix fix`);
  `deadnix --fail` (unused bindings/args). Expose all as `checks.<sys>.*` derivations so
  **`nix flake check`** validates the whole flake — the "one command fails fast" gate CI runs.
- **Pre-commit:** wire formatter + `statix` + `deadnix` via `git-hooks.nix` (formerly
  `pre-commit-hooks.nix`); it generates the `pre-commit` install step and can expose the same hooks
  as `checks.<sys>.pre-commit`, so local hooks and `nix flake check` share one definition.
- **flake-project kind:** the standard shape; layer onto an evaluable flake in order —
  `packages.default` (`stdenv.mkDerivation` or
  `buildRustPackage`/`buildGoModule`/`buildNpmPackage`), `devShells.default` (`mkShell` with
  formatter/`statix`/`deadnix`/`nix`), `apps.default` (`{ type; program; }` for `nix run`, if it
  ships an executable), `checks` for the gates, and optional `nixosModules` / `homeManagerModules`.
  Overlay-only and module-only are followup kinds.

## Source Map

| Topic                                                             | File                         |
| ----------------------------------------------------------------- | ---------------------------- |
| Binding index, scope (flake as deliverable), kinds list, related  | `README.md`                  |
| Ordered Nix overlay steps (the _what_/_in what order_)            | `runbook.md`                 |
| `nix flake init`, outputs harness, nixpkgs pin + `.lock`, layout  | `00-toolchain-and-layout.md` |
| `nixpkgs-fmt`/`alejandra`, `statix`, `deadnix`, `nix flake check` | `01-quality-gates.md`        |
| Standard flake ordering (`packages`/`devShells`/`apps`/`checks`)  | `flake-project.md`           |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Language detail (flake syntax, output
  schema, modules): the Nix language shelf `../README.md` (`02-flakes.md`, `03-flake-outputs.md`,
  `04-nixos-and-modules.md`, `05-tooling-gotchas-resources.md`). Nix-as-a-tool:
  `../../../tools/nix/`.
- `overlay-project.md` (overlay-only) and `module-project.md` (module-only) are declared followup
  kinds; add them (and refresh `source-files`) when they land.
- Re-verify default-tool choices (`nixpkgs-fmt` vs `alejandra`, `git-hooks.nix`) against upstream on
  a cadence when regenerating.
- No conflicts among the current source files.
  </content>
  </invoke>
