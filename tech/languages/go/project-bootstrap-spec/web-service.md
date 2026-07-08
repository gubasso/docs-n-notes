# Go web service — implementation-kind additions

What an **HTTP service** project adds on top of the general recipe and the Go binding: the server
entrypoint, routing, middleware, and lifecycle handling. This file owns only the **bootstrap-time
ordering**.

## Prerequisites

- The [general runbook](../../../programming/project-bootstrap/runbook.md) and the Go
  [binding runbook](runbook.md) are done — a buildable, gated module exists.

## Add these, in this order

When scaffolding an HTTP service, layer these on the buildable module in order:

1. **Server layout.** Put the entrypoint under `cmd/<name>/main.go`; keep handlers, routing, and
   business logic in `internal/`. → [00 — Toolchain & layout](00-toolchain-and-layout.md).
2. **Server & routing.** Start from the stdlib `net/http` server and `http.ServeMux` (the Go 1.22+
   mux supports method/path patterns); reach for a router (e.g. `chi`) only when you need richer
   routing or middleware ergonomics.
3. **Middleware.** Establish a middleware chain for request logging, recovery, and request IDs
   before adding routes.
4. **Configuration.** Load port, timeouts, and dependencies from env/flags with explicit defaults;
   set `ReadTimeout`/`WriteTimeout` on `http.Server` rather than the zero-value defaults.
5. **Graceful shutdown.** Handle `SIGINT`/`SIGTERM` and call `server.Shutdown(ctx)` so in-flight
   requests drain on deploy.

## Deployment (later phase)

Container images, deployment manifests, and release automation are later-phase work, not bootstrap.
Bootstrap stops at a working, gated service module. Add a Go `release-workflow-spec/` and link it
here when you set up Go releases.
