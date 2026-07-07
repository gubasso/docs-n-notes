# Nix Language

> $nix $nix-lang

Concise, example-first TLDR of the **Nix expression language** and **flakes** — a study/reference
shelf, not a full manual.

Scope split: this shelf is the **language/syntax**. For Nix-as-a-tool (installing, per-project
devshells, project migration, templates) see [`tech/tools/nix`](../../tools/nix/README.md).

## Mental model (read this first)

Nix is a **functional, declarative, lazy** expression language. There are **no statements and no
top-to-bottom execution** — the whole file is ONE expression that _evaluates to a value_ (usually an
attribute set). You describe _what things are_; Nix computes only what's actually needed (laziness).

## Files (learning order)

1. [`01-language-basics.md`](01-language-basics.md) — values, attrsets, `let/in`, functions,
   `inherit`, operators (`//`, `with`, `rec`, `?`, `${}`), `lib`/`builtins`.
2. [`02-flakes.md`](02-flakes.md) — flake structure (`inputs`/`outputs`), `follows`, the
   `eachDefaultSystem` pattern, everyday `nix` commands.
3. [`03-flake-outputs.md`](03-flake-outputs.md) — the full output schema (`packages`, `devShells`,
   `apps`, `checks`, `nixosConfigurations`, …).
4. [`04-nixos-and-modules.md`](04-nixos-and-modules.md) — the NixOS module system (`options` vs
   `config`, `mkIf`/`mkForce`), `configuration.nix`, Home Manager.
5. [`05-tooling-gotchas-resources.md`](05-tooling-gotchas-resources.md) — CLI, ecosystem
   (`flake-parts`, `crane`, `direnv`), common gotchas, best resources.

## 30-second synthesis

Learn the **language core** (attrsets + functions + `let/in`, evaluated not executed), then the
**flake output schema**, then the **NixOS module system** (`options`/`config` merging) which is a
second declarative layer on the same language. Fastest practice: `nix repl` → `:lf .`, and
`nix flake show` on real repos.
