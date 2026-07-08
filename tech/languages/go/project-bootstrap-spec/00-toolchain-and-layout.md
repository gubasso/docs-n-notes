# 00 — Toolchain & layout

The Go ecosystem choices for a fresh module: how to initialize it, the standard directory layout,
how to pin the Go version, and how the Nix devShell hosts the toolchain.

## Initialize the module

`go mod init <module-path>` creates `go.mod`. The module path is the canonical import prefix and
should be the repository URL, e.g. `github.com/<org>/<name>`. Choose it once — renaming a published
module path is disruptive. Bootstrap only needs `go.mod` (and `go.sum` once dependencies are added)
to build and test.

## Standard project layout

Go has no enforced layout, but the widely-adopted convention is:

- `cmd/<binary>/main.go` — one directory per executable; `main` packages live here, kept thin.
- `internal/` — packages private to this module; the compiler forbids imports from outside the
  module, so it is the default home for application code.
- `pkg/` — packages intentionally exported for external import. Add it **only** when you actually
  publish importable packages; otherwise prefer `internal/` and avoid premature public surface.

For a single small binary, a top-level `main.go` is enough to start; introduce `cmd/` and
`internal/` as the module grows. Bootstrap owns the _ordering_ (get a buildable module first).

## Go version pinning

`go.mod` carries two directives that pin the language and toolchain:

- `go 1.XX` — the minimum language version the module requires.
- `toolchain go1.XX.Y` — the exact toolchain used to build, so local and CI resolve the same
  compiler.

Set both now so builds are reproducible from the first commit.

## Toolchain + Nix

Host the pinned Go toolchain in the Nix devShell so local and CI share one version — see
[nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md). Keep the
Nix-provided Go version aligned with the `go`/`toolchain` directives in `go.mod`. This closes the
"works on my machine" gap before any code is written.

## Automation

`bootstrap-nix` provisions the devShell that hosts the toolchain. The steps above are the SoT; see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
