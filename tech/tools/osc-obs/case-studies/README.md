# osc-obs case studies

Narrative reflections on real OBS home-project incidents. Each case study walks through one
end-to-end fix — goal, what went wrong, mistakes hit along the way, the actual fix, the lesson
distilled into a "next time" rule, the happy path, and the final outcome. Different shape from the
topic notes in `../`: those are reference cards you grep when you already know what you're looking
for; these are stories you read once to install the lesson.

Read them top-to-bottom the first time you encounter a similar incident. After that, the sibling
topic notes are usually enough — each case study points at the relevant ones in its "See also"
section.

## Index

- [01-broken-link-drift-after-patch-rename.md](./01-broken-link-drift-after-patch-rename.md) — every
  consumer lane went `broken: patch '<new>' does not exist` simultaneously after a converger script
  `osc add`'d a new overlay patch but never `osc rm`'d the old one. The `broken` state is pre-build
  (source-service link expansion failure), distinct from `unresolvable` / `failed`, and needs its
  own diagnostic recipe. Recovery is one workspace commit; prevention is making the converger
  enumerate-and-prune, not append-only.
- [02-libexpat-abi-override-via-sles-update-branch.md](./02-libexpat-abi-override-via-sles-update-branch.md)
  — overriding a buildroot ABI by branching a SUSE Update package into the home project so the
  resolver's path order naturally prefers it. Two foot-guns: (a) binary RPM name ≠ source pkg name
  (`libexpat1` ships from `expat`), (b) `openSUSE:Factory` is rarely the right branch source for
  SLES overlay work (Tumbleweed-newest toolchain drift). The 4-arg `osc branch` form solves both.

## How to read

Each case study uses the same nine-section shape so you can navigate them the same way:

1. **TL;DR** — the lesson in one paragraph.
2. **Goal** — what "done" looks like.
3. **Challenge — what you'll trip over** — the conceptual hazard, before any commands.
4. **What went wrong (timeline)** — chronological, including dead-ends and dropped sub-tasks.
5. **Mistakes / foot-guns hit along the way** — smaller items that ate time, each with the rule that
   prevents recurrence.
6. **What I did to fix it** — the actual commands that landed.
7. **Correct path next time — the rule distilled** — the durable lesson, as numbered rules.
8. **Happy path** — the six-or-so-command sequence you'd run if you knew everything up front.
9. **Final result** — what the project state looked like after.

A "Cross-cutting concerns" section is added when one fix surfaced unrelated side effects worth
flagging for follow-up.

## Audience

These are project-agnostic — the case studies use `<angle>` placeholders for any home-project
namespace (`<user>`, `<project>`), satellite-pkg names, and converger-script filenames. Public
upstream names (`expat`, `libexpat1`, `python311`, `cloud-regionsrv-client`,
`SUSE:SLE-15-SP<n>:Update`, distro lane names like `SLE_15_SP6`) stay concrete because they're
publicly known and aid clarity.

Concrete per-incident details — real home-project names, full patch filenames, repository paths,
incident timestamps — live with the originating project's `.plan/` or `docs/` tree, not here.
