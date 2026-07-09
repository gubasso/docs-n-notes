# 03 — Comments and Code as SoT

Code is the source of truth for behavior. Documentation should not restate obvious behavior that the
code can express with names, types, and structure. Comments are reserved for rationale that would
disappear if it were not written next to the code.

## Default rule

Write the code so the common path reads without comments. Then ask: would removing this comment
confuse a future reader? If yes, keep or improve the comment. If no, delete it or rename the code.

The test is intentionally reader-centered. It does not ask whether the comment is true, whether it
was useful while writing, or whether it feels harmless. It asks whether a future maintainer loses
important context when the comment disappears. If not, the comment is noise competing with the code.

This rule does not mean "never comment." It means comments must carry load. Ousterhout argues that
software complexity is reduced when comments capture information not obvious from code. Fowler's
code smell catalog treats comments as a smell when they compensate for unclear names or poor
structure. The useful synthesis is direct: keep comments that explain why; remove comments that only
narrate what.

Sources: <https://www.informit.com/articles/article.aspx?p=2952392&seqNum=24> and
<https://martinfowler.com/bliki/CodeSmell.html>.

Treat tests and types as documentation too. A type can make invalid states unrepresentable. A test
can lock down a behavioral contract. A comment should not carry a contract that the code can enforce
directly.

Use proximity as the placement rule. If the rationale applies only to one branch, put the comment
next to that branch. If it applies to a module boundary, put it in the module header. If it applies
to the whole project, it does not belong in a code comment; write the rule in the owning doc and
link to it when local code would otherwise look surprising.

## Load-bearing comments

Keep comments that explain:

- Rationale for a surprising branch.
- Boundary conditions from an external system.
- Non-obvious invariants that must not be violated.
- A deliberate trade-off that looks wrong without context.
- A link to the ADR that owns a broader decision.

Good comments should be stable. If a comment needs frequent edits because it mirrors code behavior,
it probably belongs in a name, type, test, or reference table instead.

Use comments to point to the source of truth, not to duplicate it. A line can say "ADR-<number>
requires this order because `<system>` rejects late normalization." The ADR owns the decision. The
comment explains why this local code shape is not accidental.

Good comments are usually short. One or two lines near the surprising code beats a long block far
away. If the rationale needs more room, write the durable explanation or ADR and link to it. The
comment should preserve the local reason the code looks the way it does.

Load-bearing comments are especially valuable at boundaries: remote APIs, process exits, file
formats, compatibility constraints, performance traps, security checks, and cleanup ordering. Those
constraints often look arbitrary when the reader only sees local code.

Keep comments falsifiable. A comment like "this is important" does not give a maintainer anything to
check. A comment like "`<system>` rejects requests when the token is normalized twice" states a
condition that can be verified against behavior, tests, or reference docs.

## Delete or rename

Delete comments that restate the next line:

```python
# Bad: increments the retry count.
retry_count += 1
```

Rename code when the comment is compensating for vague names:

```python
# Bad: check if the operation can run now.
if ok(item):
    run(item)

# Better.
if command_window_allows(item):
    run(item)
```

Move facts out of comments when the fact is reference material:

```python
# Bad: three paragraphs listing every remote status value.
if remote_status == "ready":
    start()
```

Put the status matrix in `<project>/docs/reference/<topic>/` and keep only a local invariant if the
code has one:

```python
# The remote API reports "ready" only after replication catches up.
if remote_status == "ready":
    start()
```

## Boundary examples

Keep a boundary-condition comment:

```python
# `<system>` treats missing and empty tags differently; preserve `None`.
payload["tags"] = tags
```

Keep an invariant comment when the type cannot express it:

```rust
// The provider signs the raw path, so normalization must happen before this point.
let signature = sign(raw_path);
```

Prefer an ADR link for broader rationale:

```python
# ADR-<number>: cleanup runs after upload so retries can inspect artifacts.
cleanup_after_upload()
```

Do not put the whole ADR in the comment. The local comment explains the surprising code shape. The
ADR owns the decision. See [04 — Single Source of Truth](./04-single-source-of-truth.md).

Another common boundary is a cleanup or retry path:

```python
# Bad: retry the command three times.
for attempt in range(3):
    run_command()

# Better: `<system>` may report success before the artifact is readable.
for attempt in range(3):
    run_command()
```

The improved comment says why the retry exists. The loop already says what happens.

A naming fix can remove an entire comment:

```rust
// Bad: the item is ready when all checks passed.
if ready(item) {
    publish(item);
}

// Better.
if all_publish_checks_passed(item) {
    publish(item);
}
```

When a comment and code disagree, trust neither blindly. Read the owning ADR, reference page, tests,
and current behavior. Then update the non-owner so there is one truthful source again.

Do not use comments as a parking lot for TODOs unless the project has an explicit policy for them.
Open work belongs in the issue tracker, backlog, or draft area. A TODO comment without ownership,
context, or a linked decision is usually stale the moment it lands.

## Sources

- Ousterhout, comment purpose: <https://www.informit.com/articles/article.aspx?p=2952392&seqNum=24>
- Fowler, code smells: <https://martinfowler.com/bliki/CodeSmell.html>
