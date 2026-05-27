---
digest-of: tech/programming/best-practices
last-synced: 2026-05-27
source-files:
  - licensing.md
  - madr-template.md
  - operational-responsibilities.md
  - pre-commit.md
  - refactor-guideline-excerpt.md
  - refactor-migration-guideline.md
  - refactor-plan-templates.md
  - refactor-refusal-list.md
token-estimate: 1800
---

# AGENTS

## Scope

Cross-cutting best practices: licensing, ADR templates, DevOps checklists, pre-commit hooks, and the
cross-language refactor/migration guideline with its refusal list and plan templates.

## Key Points

### Licensing

- OSI-approved licenses. Defaults: Apache 2.0 (code), CC BY-SA 4.0 (docs). Copyleft:
  GPL-2.0-or-later.

### MADR Template

- Markdown Architecture Decision Record v3. Sections: Context, Decision Drivers, Considered Options,
  Decision Outcome, Consequences, Validation, Pros/Cons.
- Write ADR when: hard to reverse, deviates from contract, non-obvious choice, forced by
  target-language idiom.
- Numbering: 0001-0002 reserved (rewrite decision, parity boundary), 0003+ for implementation, 9999
  for postmortem.

### Operational Responsibilities

- 8-section DevOps checklist: Setup, Baseline Operations, Security Maintenance, Logging/Monitoring,
  Backup/DR, Performance/Capacity, Documentation/Compliance, Review/Improvement.

### Cross-Language Refactor/Migration Guideline

- **Core principle**: Preserve external contract, re-derive internal implementation from contract +
  target idioms. No transliteration.
- **Six gated phases**: A (contract extraction) -> B (freeze behavior) -> C (idiomatic design, NO
  source code access) -> D (implementation under guardrails) -> E (differential/property/fuzz/shadow
  validation) -> F (parallel-run, canary, cutover, decommission).
- **Phase C is the highest-leverage anti-transliteration guardrail**: design only from contract +
  target canon.

### Refusal List (16 Translation Smells)

1. Class-hierarchy mirrored as traits. 2. Shell pipeline as subprocess chain. 3. Exception-to-Result
   mechanical mapping. 4. Source concurrency model carried over. 5. Callbacks where async/await
   fits. 6. Getter/setter in Go. 7. `Vec<Box<dyn Trait>>` mirroring `List<Interface>`. 8. null/None
   checks instead of typed absence. 9. String-typed configuration. 10. Source-side file/module
   names. 11. Mirrored test structure. 12. Comments translated verbatim. 13. Shell-isms in
   higher-level targets. 14. Hand-rolled CLI parsing. 15. Mirroring serialization formats. 16.
   Logging strings instead of structured fields.

### Plan Templates

- Full plan directory: `AGENTS.md`, `MANIFEST.yaml`, `00-EXECUTION-GUIDE.md`, `00-OVERVIEW.md`,
  `01-CONTRACT.md` (Phase A), `02-CHARACTERIZATION.md` (Phase B), `03-DESIGN.md` (Phase C),
  `04-ANTI-TRANSLITERATION.md`, `05-IMPLEMENTATION-GUARDRAILS.md` (Phase D),
  `06-VERIFICATION-PLAN.md` (Phase E), `07-CUTOVER.md` (Phase F), `GLOSSARY.md`, `SEMANTIC-GAPS.md`,
  review report template.

### LLM Translation Research

- Correct-translation rates 2.1-47.3% (IBM ICSE 2024). Parity tests in Phase E are not optional.
- Success gated on validation loop, not raw generation (Google 2025).
- Semantic gaps (integer overflow, string encoding, concurrency) require per-pair feature mapping.

## Source Map

| Topic                                           | File                              |
| ----------------------------------------------- | --------------------------------- |
| SPDX licensing defaults                         | `licensing.md`                    |
| MADR v3 template and when to write              | `madr-template.md`                |
| DevOps operational checklist                    | `operational-responsibilities.md` |
| Pre-commit hook config snippet                  | `pre-commit.md`                   |
| Guideline embedded excerpt (fallback)           | `refactor-guideline-excerpt.md`   |
| Full refactor/migration guideline (14 sections) | `refactor-migration-guideline.md` |
| Plan directory templates (12 files)             | `refactor-plan-templates.md`      |
| 16-smell anti-transliteration refusal list      | `refactor-refusal-list.md`        |

## Maintenance Notes

- The refactor-migration guideline is the canonical source; the excerpt is a fallback for skills
  that cannot resolve it.
- LLM research references should be checked when significant new translation studies publish.
