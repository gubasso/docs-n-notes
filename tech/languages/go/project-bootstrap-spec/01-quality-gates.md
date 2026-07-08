# 01 — Quality gates

The Go concretion of the general
[quality gates](../../../programming/project-bootstrap/04-quality-gates.md) and
[security baseline](../../../programming/project-bootstrap/06-security-baseline.md) chapters.

## Formatter — `gofmt` / `goimports`

`gofmt` is the canonical, non-configurable formatter; `goimports` is the superset that also fixes
the import block. Enforce in CI that no file needs reformatting:

```bash
gofmt -l .          # lists files that are not gofmt-clean; non-empty output = fail
goimports -l .      # same, plus import grouping/removal
```

## Linter — `go vet` + `golangci-lint`

`go vet` ships with the toolchain and catches correctness issues the compiler does not.
`golangci-lint` is the standard meta-linter that aggregates many linters behind one config
(`.golangci.yml`):

```bash
go vet ./...
golangci-lint run ./...
```

Run both in CI so lint failures block the build.

## Tests — `go test` + race detector

Run the full suite with the race detector enabled so data races surface in CI:

```bash
go test -race ./...
```

## Security — `govulncheck`

`govulncheck` is the official vulnerability scanner; it reports only advisories that actually reach
the code paths your module calls, keeping the security baseline low-noise:

```bash
govulncheck ./...
```

Run it in CI so a vulnerable dependency cannot merge.

## Pre-commit wiring

Wire `gofmt`/`goimports`, `go vet`, and `golangci-lint` into the pre-commit hooks from the general
[04 — Quality gates](../../../programming/project-bootstrap/04-quality-gates.md) so failures surface
locally in seconds. Keep the heavier `go test -race` and `govulncheck` in CI (and a task-runner
recipe) rather than on every commit.
