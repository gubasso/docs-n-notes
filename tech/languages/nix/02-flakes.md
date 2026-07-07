# Flakes

> $nix $nix-flakes

A flake is a standardized, reproducible project: a `flake.nix` (declares inputs + outputs) plus an
auto-generated `flake.lock` (pins exact versions). Think `package.json` + `package-lock.json`, for
Nix.

## Minimal shape

```nix
{
  description = "...";              # metadata string

  inputs = { ... };                # external dependencies (other flakes)

  outputs = { self, ... }: { ... };# a FUNCTION: takes resolved inputs → outputs set
}
```

The whole file is one attribute set with those three keys.

## Inputs

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";  # github:owner/repo/ref
  rust-overlay.url = "github:oxalica/rust-overlay";     # no /ref → default branch
  rust-overlay.inputs.nixpkgs.follows = "nixpkgs";      # reuse OUR nixpkgs (dedupe)
  flake-utils.url = "github:numtide/flake-utils";
};
```

- `.follows` = "make this input use the same sub-input we already have" — avoids two nixpkgs copies.
  Add it for every input that carries its own nixpkgs.

## Outputs (the function)

```nix
outputs = { self, nixpkgs, rust-overlay, flake-utils }: ...
```

- Params are matched **by name** and come from the `inputs` keys, **plus `self`** (a reference to
  this flake). You may rename inputs, but both places must match.

## The `eachDefaultSystem` pattern (per-arch boilerplate)

Most outputs are keyed by system (`x86_64-linux`, `aarch64-darwin`, …). `flake-utils` generates them
for you:

```nix
outputs = { self, nixpkgs, rust-overlay, flake-utils }:
  flake-utils.lib.eachDefaultSystem (system:      # a function called once per system
    let
      pkgs = import nixpkgs {
        inherit system;                            # system = system
        overlays = [ (import rust-overlay) ];      # extend pkgs with rust-bin.*
      };
      toolchain = pkgs.rust-bin.fromRustupToolchainFile ./rust-toolchain.toml;
    in {                                           # ← the returned outputs set
      devShells.default = pkgs.mkShell {
        packages = [ toolchain pkgs.just pkgs.cargo-nextest ];
        shellHook = ''echo "dev shell ready"'';    # runs at `nix develop`, NOT at eval
      };
    });
```

Read it as: "one expression describing a set of outputs." Nothing runs top-to-bottom; `let` names
sub-values, the `{ }` after `in` _is_ the value. `shellHook` is just a stored string that a later
runtime phase executes.

## Everyday commands

```bash
nix develop            # enter devShells.default (with direnv: `use flake` in .envrc)
nix build .#name       # build packages.<sys>.name → ./result   (default if omitted)
nix run  .#name        # run apps.<sys>.name
nix flake check        # build checks.* + evaluate outputs (CI gate)
nix fmt                # run formatter.<sys>
nix flake show         # print the whole output tree of any flake  ← great for learning
nix flake metadata     # inputs + lock info
nix flake update       # refresh ALL inputs → rewrites flake.lock
nix flake lock --update-input nixpkgs   # bump just one input
nix repl               # then `:lf .` to load this flake and poke at it
```
