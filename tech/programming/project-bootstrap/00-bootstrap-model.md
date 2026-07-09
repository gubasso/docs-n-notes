# 00 — Bootstrap model

**Bootstrap** is the once-per-project phase that takes an empty repository to a scaffolded,
quality-gated baseline ready for feature work. It is a **how-to guide** in the Diátaxis sense —
task-oriented, ordered, assuming you know what a project is and just need the steps — not a
tutorial. See [docs-design / Diátaxis zones](../docs-design/01-diataxis-zones.md).

## The once-per-project phase

Bootstrap runs exactly once per project, at creation. It precedes and is distinct from the
[release workflow](../release-workflow/README.md), which is a _later_ phase concerned with
publishing and promotion. Keeping the two phases separate avoids a common trap: treating "set up the
project" and "set up releases" as one undifferentiated blob. Bootstrap ensures the project is
_ready_; release setup makes it _publishable_.

## The three-layer ownership model

Every bootstrap fact has exactly one owner, arranged in three descending layers:

1. **General** — `tech/programming/project-bootstrap/` (this tree). Universal, cross-language steps:
   repo creation, `.gitignore`/`LICENSE`/`README`, governance docs, dev environment, quality gates,
   CI, branch-protection reference, security baseline. The [`runbook.md`](./runbook.md) is the
   spine.
2. **Language** — `tech/languages/<lang>/project-bootstrap-spec/`. Ecosystem choices only: the crate
   layout and toolchain for Rust, packaging for Python, and so on. It _overlays_ the general spine
   and never restates it.
3. **Implementation-kind** — a flat file such as `cli-project.md` inside the language binding
   (promote to a subdirectory only when it grows to multiple chapters). Shape-specific additions:
   CLI arg-parsing/logging, library public API, service health/config. It owns only the
   bootstrap-time _ordering_ and delegates the detailed _how_ to any existing spec.

## One owner per fact

The layers link; they never duplicate. Branch protection lives under
[`tools/git/branch-protection/`](../../tools/git/branch-protection/) and is _referenced_ from the
runbook, not copied. Release setup lives in [release-workflow](../release-workflow/README.md). This
is the single-source-of-truth discipline from
[docs-design / single source of truth](../docs-design/04-single-source-of-truth.md): duplicated
instructions drift, so each fact is owned in one place and pointed to from everywhere else.

## Relationship to the release phase

```text
bootstrap (once, at creation)          release-workflow (recurring, per version)
  repo → foundations → gates    ──────►  branch model → release PR → publish
```

When the bootstrap runbook is complete, the project is ready to adopt the release workflow. The two
runbooks cross-link at their shared boundary (repo creation and branch protection).

## References

- [GitHub Open Source Guide — Starting a project](https://opensource.guide/starting-a-project/)
- [Diátaxis](https://diataxis.fr/) — the how-to vs tutorial distinction.
