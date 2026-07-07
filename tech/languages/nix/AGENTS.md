---
digest-of: tech/languages/nix
last-synced: 2026-07-07
source-files:
  - README.md
  - 01-language-basics.md
  - 02-flakes.md
  - 03-flake-outputs.md
  - 04-nixos-and-modules.md
  - 05-tooling-gotchas-resources.md
token-estimate: 2600
---

# AGENTS

## Scope

Concise, example-first reference for the **Nix expression language** and **flakes**. Language/syntax
focus only; Nix-as-a-tool (install, devshells, templates, migration) lives in `tech/tools/nix/`.

## Key Points

- **Evaluation model**: Nix is functional, declarative, lazy. No statements / no top-to-bottom
  execution — a file is ONE expression evaluating to a value. `let` bindings are order-independent
  and mutually visible; `if` requires `else`.
- **Core syntax**: attrsets `{ k = v; }` (`;`-terminated), lists (space-separated), functions are
  single-arg lambdas `x: body` (currying via juxtaposition), attrset args matched **by name** with
  `?` defaults and `...` ellipsis and `@`-binding. `inherit x;` / `inherit (set) a b;`. Operators:
  `//` (shallow right-wins merge), `with`, `rec`, `${}` interpolation. `import` is a function, not a
  statement.
- **Flakes**: `{ description; inputs; outputs }`. `outputs` is a function whose params come from
  `inputs` keys plus `self`. `.follows` dedupes shared inputs. `flake.lock` pins versions — commit
  it. `eachDefaultSystem (system: …)` generates per-arch outputs.
- **Output schema**: `packages`/`devShells`/`apps`/`checks`/`formatter` are per-system with
  `.default`; `nixosConfigurations`/`homeConfigurations` are NOT per-system.
- **NixOS module system**: modules are `{ config, pkgs, lib, ... }:` functions with
  `imports`/`options`/`config`; `options` declare settings, `config` assigns, NixOS merges all
  `config`. Priority helpers `mkDefault`/`mkForce`/`mkIf`. Home Manager reuses the same module
  system for per-user config.
- **Gotchas**: flakes only see git-tracked files; pure eval (no time/env/network); `//` is shallow;
  unstable vs release branch; eval ≠ build ≠ runtime.

## Source Map

| Topic                                                            | File                              |
| ---------------------------------------------------------------- | --------------------------------- |
| Shelf index + mental model                                       | `README.md`                       |
| Language syntax (values, functions, operators, `lib`/`builtins`) | `01-language-basics.md`           |
| Flake structure, inputs/outputs, `eachDefaultSystem`, commands   | `02-flakes.md`                    |
| Flake output schema + real package/app examples                  | `03-flake-outputs.md`             |
| NixOS module system + Home Manager                               | `04-nixos-and-modules.md`         |
| Tooling, ecosystem inputs, gotchas, resources                    | `05-tooling-gotchas-resources.md` |

## Maintenance Notes

- Cross-references `tech/tools/nix/` (tool usage) — keep the language/tool split intact.
- Regenerate when any source file here changes or new topic files are added.
- Authored as a TLDR study shelf, not a full manual; intentionally omits deep derivation internals
  (see Nix Pills, linked in `05-...`).
