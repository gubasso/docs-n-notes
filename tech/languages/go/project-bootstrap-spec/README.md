# Go — bootstrap a new project (spec/binding)

The Go binding of
[`tech/programming/project-bootstrap/`](../../../programming/project-bootstrap/README.md). It
applies the general once-per-project recipe with concrete Go tooling — module scaffolding, standard
layout, toolchain pinning, and the gofmt/vet/golangci-lint/govulncheck quality gates — and links to
Go implementation-kinds.

This binding **overlays** the general spine; it does not restate it. Read the general recipe first,
then the Go specifics here.

## How to use this binding

1. Read the general [hub](../../../programming/project-bootstrap/README.md) and
   [general runbook](../../../programming/project-bootstrap/runbook.md) — the cross-language _what_.
2. Follow this [`runbook.md`](./runbook.md) for the Go-specific overlay steps.
3. Jump to your implementation-kind file (e.g. [`cli-project.md`](./cli-project.md) or
   [`web-service.md`](./web-service.md)).

## Index

| # | Chapter                                            | One-line hook                                                                  |
| - | -------------------------------------------------- | ------------------------------------------------------------------------------ |
| 0 | [Toolchain & layout](./00-toolchain-and-layout.md) | `go mod init`, module path, `cmd/`/`internal/`/`pkg/`, Go version pin + Nix.   |
| 1 | [Quality gates](./01-quality-gates.md)             | `gofmt`/`goimports`, `go vet` + `golangci-lint`, `go test -race`, govulncheck. |

## Implementation kinds

- [`cli-project.md`](./cli-project.md) — Go CLI: the bootstrap-time ordering for command surface,
  flags/subcommands (`flag` or `cobra`), and config.
- [`web-service.md`](./web-service.md) — Go HTTP service: the bootstrap-time ordering for the
  server, routing (`net/http` or a router), and graceful shutdown.

`library-project.md` is a followup; add it when you bootstrap a Go library.

## Related

- [General project-bootstrap](../../../programming/project-bootstrap/README.md) — the cross-language
  recipe this binding overlays.
- [nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md) — how the Nix
  devShell hosts the Go toolchain.

The Go [`release-workflow-spec/`](../release-workflow-spec/README.md) (the later release &
publishing phase) is **intentionally deferred** — the linked placeholder explains that it stays
unimplemented until an explicit Go release need arises.
