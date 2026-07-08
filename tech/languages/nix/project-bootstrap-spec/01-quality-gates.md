# 01 — Quality gates

The Nix concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) chapter, for a flake
that is the deliverable. Formatting, linting, and dead-code detection over the Nix code itself, all
gated by `nix flake check`.

## Formatter — `nixpkgs-fmt` or `alejandra`

Pick one canonical formatter and expose it as `formatter.<sys>` so `nix fmt` uses it:

- **`nixpkgs-fmt`** — the conservative, widely-used default.
- **`alejandra`** — an opinionated, faster alternative.

Enforce in CI by checking formatting is clean, e.g.:

```bash
nix fmt -- --check          # via formatter.<sys>
# or directly:
alejandra --check .
nixpkgs-fmt --check .
```

For multi-language repos, `treefmt-nix` wires several formatters behind one `nix fmt`.

## Linter — `statix`

`statix` flags Nix anti-patterns and suggests idiomatic fixes:

```bash
statix check .              # report
statix fix .                # auto-apply safe suggestions
```

## Dead code — `deadnix`

`deadnix` finds unused `let` bindings and function arguments:

```bash
deadnix --fail .            # non-zero exit on findings (CI-friendly)
```

## `nix flake check` — the gate

Expose the format/lint checks as `checks.<sys>.*` derivations so a single command validates the
whole flake (outputs evaluate, checks build/pass):

```bash
nix flake check
```

This is the Nix analogue of "one command fails fast" and is what CI runs. See the output schema for
`checks` in [`03-flake-outputs.md`](../03-flake-outputs.md).

## Pre-commit wiring — `git-hooks.nix`

Wire `nixpkgs-fmt`/`alejandra`, `statix`, and `deadnix` into git hooks with
[`git-hooks.nix`](https://github.com/cachix/git-hooks.nix) (formerly `pre-commit-hooks.nix`). It
generates a `pre-commit` install step and can also expose the same hooks as a
`checks.<sys>.pre-commit` derivation, so local hooks and `nix flake check` share one definition.
This slots into the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) hook layer.
