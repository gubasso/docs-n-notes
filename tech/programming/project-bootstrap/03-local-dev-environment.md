# 03 — Local dev environment

A reproducible, per-project development environment so every contributor (and every CI runner) gets
the same toolchain, and a cross-editor formatting baseline.

## Nix devShell + `.envrc`

A per-project Nix flake devShell pins the toolchain and dev tools declaratively, so the environment
is reproducible rather than "whatever is on your machine". Add an `.envrc` containing `use flake` so
[direnv](https://direnv.net/) loads the shell automatically on `cd`, and reuse the same flake in CI
so local and CI environments cannot drift apart.

The flake shape (a `devShells.default` built with `mkShell`), the direnv wiring, and per-language
starting templates are owned by
[`tools/nix/02 — Per-project devShell`](../../tools/nix/02-per-project-devshell.md) — follow it for
the template; the language binding names the toolchain that goes inside.

## `.editorconfig`

`.editorconfig` sets whitespace, charset, and final-newline rules that every editor honors, so
formatting is consistent regardless of individual editor config. Keep it aligned with the language
formatter (chapter [04](./04-quality-gates.md)) so the two never fight — the formatter is
authoritative for code, `.editorconfig` covers everything else.

## Automation

`bootstrap-nix` scaffolds the flake devShell + `.envrc`; `bootstrap-editorconfig` writes the
`.editorconfig` and aligns it with the detected formatter/linter. The setup above is the SoT; see
[07 — Automation with cog](./07-automation-with-cog.md).
