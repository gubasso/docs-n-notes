---
digest-of: tech/languages/go/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
  - web-service.md
token-estimate: 780
---

# AGENTS

## Scope

Go binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project Go setup
that takes an empty repo to a scaffolded, gated, buildable module ready for feature work. It
**overlays** the general spine (repo, license, governance, dev env, CI, security) and never restates
it; it owns only the Go ecosystem choices and the two implementation-kind orderings (CLI, HTTP
service). Do the general steps first, then this overlay.

## Key Points

- **Module init:** `go mod init <module-path>` creates `go.mod`. The module path is the canonical
  import prefix and should be the repo URL (`github.com/<org>/<name>`); choose it once — renaming a
  published path is disruptive. Bootstrap needs only `go.mod` (and `go.sum` once deps land) to build
  and test.
- **Layout (convention, not enforced):** `cmd/<binary>/main.go` — one dir per executable, `main`
  packages kept thin; `internal/` — module-private packages, the default home for application code;
  `pkg/` — added **only** when actually publishing importable packages, else prefer `internal/` and
  avoid premature public surface. A single small binary can start with a top-level `main.go`;
  introduce `cmd/`/`internal/` as it grows. Bootstrap owns the ordering: buildable module first.
- **Version pin:** `go 1.XX` (minimum language version) + `toolchain go1.XX.Y` (exact build
  toolchain) directives in `go.mod`, set from the first commit for reproducible builds. Host the
  pinned Go in the Nix devShell so local and CI share one version, kept aligned with the `go.mod`
  directives (`nix/02-per-project-devshell`).
- **Quality gates:** `gofmt` (canonical, non-configurable) / `goimports` (superset, fixes imports)
  for format; `go vet` (ships with toolchain) + `golangci-lint` (meta-linter, `.golangci.yml`) for
  lint; `go test -race ./...` for tests; `govulncheck ./...` (official, reachability-aware,
  low-noise security baseline). Wire `gofmt`/`goimports`, `go vet`, `golangci-lint` into pre-commit;
  keep the heavier `go test -race` and `govulncheck` in CI (and a task-runner recipe).
- **CLI kind:** entrypoint at `cmd/<name>/main.go`, `main` thin, logic in `internal/`; arg parsing
  via stdlib `flag` (single command) or `cobra` (subcommand tree, help/completion); return errors up
  to `main` and map to exit codes in one place (not `os.Exit` deep in the tree); config precedence
  flag → env → config-file (e.g. `cobra` + `viper`) with explicit defaults.
- **Web-service kind:** entrypoint at `cmd/<name>/main.go`, handlers/routing/logic in `internal/`;
  start from stdlib `net/http` + `http.ServeMux` (Go 1.22+ method/path patterns), reach for a router
  (e.g. `chi`) only for richer routing/middleware; middleware chain (request logging, recovery,
  request IDs) before routes; load port/timeouts/deps from env/flags with explicit defaults and set
  `ReadTimeout`/`WriteTimeout` on `http.Server`; graceful shutdown on `SIGINT`/`SIGTERM` via
  `server.Shutdown(ctx)`.
- **Automation:** `bootstrap-nix` provisions the devShell; `bootstrap-precommit` +
  `bootstrap-taskrunner` wire gates; `bootstrap-ci` for CI. These chapters are the SoT; the
  SoT-vs-cog contract lives in general `07-automation-with-cog.md`.

## Source Map

| Topic                                                                | File                         |
| -------------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related        | `README.md`                  |
| Ordered Go overlay steps (the _what_/_in what order_)                | `runbook.md`                 |
| `go mod init`, module path, `cmd/`/`internal/`/`pkg/`, version + Nix | `00-toolchain-and-layout.md` |
| `gofmt`·`goimports` / `go vet`·`golangci-lint` / `-race` / vulncheck | `01-quality-gates.md`        |
| CLI bootstrap ordering (command layout, flags/cobra, exit, config)   | `cli-project.md`             |
| HTTP-service ordering (server, routing, middleware, shutdown)        | `web-service.md`             |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Nix devShell host:
  `../../../tools/nix/02-per-project-devshell.md`.
- `library-project.md` is a declared followup kind; add it (and refresh `source-files`) when a Go
  library is bootstrapped.
- The Go `release-workflow-spec/` (release & publishing phase — binary distribution via release
  archives, `go install`, GoReleaser; container images and deploy manifests) is **intentionally
  deferred**: it is a placeholder that stays unimplemented until an explicit Go release need arises.
  Bootstrap stops at a working, gated module. Do not claim a full release shelf exists.
- No conflicts among the current source files.
