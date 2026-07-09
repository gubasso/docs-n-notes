# Go Release Workflow Spec — placeholder (intentionally unimplemented)

The Go binding of the general
[`tech/programming/release-workflow/`](../../../programming/release-workflow/README.md) is
**deliberately not written yet**. Unlike the [rust](../../rust/release-workflow-spec/README.md) and
[python](../../python/release-workflow-spec/README.md) bindings, there is no committed Go release &
publishing shelf, and this file is the only thing here.

## Status

**Deferred — unimplemented until explicit request and need.** This shelf will stay empty until there
is both an explicit request and a concrete need — i.e. a real Go project in this ecosystem being set
up to publish releases. It is not a gap to backfill speculatively; keeping it as a single
placeholder (rather than a skeleton of empty chapters) preserves the repo's one-owner-per-fact
discipline and avoids stub content that drifts.

## When you do need it

1. Bootstrap the Go project with [`../project-bootstrap-spec/`](../project-bootstrap-spec/README.md)
   first — that stops at a buildable, gated module.
1. When a real release need arises, replace this placeholder with a full shelf following the same
   per-language skeleton as the [rust](../../rust/release-workflow-spec/README.md) and
   [python](../../python/release-workflow-spec/README.md) bindings.

The likely Go specifics to capture then: module version tags (`vX.Y.Z`, and `/vN` import paths for
major versions ≥ 2), [`GoReleaser`](https://goreleaser.com/) for build + publish, and the Go module
proxy / `pkg.go.dev` as the distribution surface (there is no central registry upload — publishing a
Go module _is_ pushing a tag).
