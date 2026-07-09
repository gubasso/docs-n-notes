# 03 — Local dev environment

A reproducible, per-project development environment so every contributor (and every CI runner) gets
the same toolchain, and a cross-editor formatting baseline.

## Nix devShell + `.envrc`

A per-project Nix flake devShell pins the toolchain and dev tools declaratively, so the environment
is reproducible rather than "whatever is on your machine". The idiomatic shape is a flake using
`flake-utils.eachDefaultSystem` (or `forAllSystems`) over `nixpkgs`, exposing a `devShells.default`
built with `mkShell`:

```nix
{
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  inputs.flake-utils.url = "github:numtide/flake-utils";
  outputs = { nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let pkgs = import nixpkgs { inherit system; };
      in { devShells.default = pkgs.mkShell { packages = [ /* tools */ ]; }; });
}
```

Add an `.envrc` containing `use flake` so [direnv](https://direnv.net/) loads the shell
automatically on `cd`. CI reuses the same flake, so local and CI environments cannot drift apart.
References: [Flakes (NixOS wiki)](https://wiki.nixos.org/wiki/Flakes),
[Nix devShell intro](https://nixos-and-flakes.thiscute.world/development/intro).

## `.editorconfig`

`.editorconfig` sets whitespace, charset, and final-newline rules that every editor honors, so
formatting is consistent regardless of individual editor config. Keep it aligned with the language
formatter (chapter [04](./04-quality-gates.md)) so the two never fight — the formatter is
authoritative for code, `.editorconfig` covers everything else.

## Automation

`bootstrap-nix` scaffolds the flake devShell + `.envrc`; `bootstrap-editorconfig` writes the
`.editorconfig` and aligns it with the detected formatter/linter. The setup above is the SoT; see
[07 — Automation with cog](./07-automation-with-cog.md).
