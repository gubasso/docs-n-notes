# Runbook — bootstrap a new Go project

The ordered, **once-per-project** Go-specific steps, overlaying the general spine. Each step links
to the chapter that explains the _why_; this page is only the _what_ and _in what order_.

Do the general steps first (repo, license, governance, dev env, CI, security) from the
[general runbook](../../../programming/project-bootstrap/runbook.md); the steps below are the Go
overlay that slots into it.

## Prerequisites

- The [general bootstrap runbook](../../../programming/project-bootstrap/runbook.md) is understood —
  repo created, foundations and governance in place.
- A Nix devShell exists (or will) to host the Go toolchain — see
  [nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md).

## Steps

1. **Initialize the module.** `go mod init <module-path>` (e.g. `github.com/<org>/<name>`) to create
   `go.mod`. → [00 — Toolchain & layout](00-toolchain-and-layout.md).

2. **Lay out the module.** Add `cmd/`, `internal/`, and (only if publishing importable packages)
   `pkg/` as needed. → [00 — Toolchain & layout](00-toolchain-and-layout.md).

3. **Pin the Go version.** Set the `go` and `toolchain` directives in `go.mod` and wire the same Go
   version into the Nix devShell so local and CI match. →
   [00 — Toolchain & layout](00-toolchain-and-layout.md),
   [nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md). _Automate:_
   `bootstrap-nix`.

4. **Configure quality gates.** `gofmt`/`goimports` for format, `go vet` + `golangci-lint` for lint,
   `go test -race` for tests, and `govulncheck` for the security baseline; wire them into
   pre-commit. → [01 — Quality gates](01-quality-gates.md). _Automate:_ `bootstrap-precommit`,
   `bootstrap-taskrunner`.

5. **Pick the implementation kind.** For a CLI, follow [`cli-project.md`](cli-project.md); for an
   HTTP service, follow [`web-service.md`](web-service.md); a library is a followup.

6. **Continue the general spine.** Return to the
   [general runbook](../../../programming/project-bootstrap/runbook.md) for governance, CI, and
   security if not already done. _Automate:_ `bootstrap-ci`.

## Reference

- [00 — Toolchain & layout](00-toolchain-and-layout.md) · [01 — Quality gates](01-quality-gates.md)
  · [general runbook](../../../programming/project-bootstrap/runbook.md) ·
  [nix/02 — Per-project devShell](../../../tools/nix/02-per-project-devshell.md)
