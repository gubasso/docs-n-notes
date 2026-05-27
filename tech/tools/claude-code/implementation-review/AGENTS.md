---
digest-of: tech/tools/claude-code/implementation-review
last-synced: 2026-05-27
source-files:
  - report-template.md
  - severity-levels.md
token-estimate: 500
---

# AGENTS

## Scope

Implementation review report format and severity level definitions used by
`implementation-reviewer`, `plan-reviewer`, and related review skills.

## Key Points

### Report Structure

Sections in order: Verdict, Plan Assessment, Findings (F-001...), Verification Checklist, Tests
(Executed + Recommended), Open Questions, Positive Notes, References.

### Finding Format

Each finding: Severity, Category, Location, Issue (1-3 sentences), Evidence (never empty),
Recommendation (actionable). Ordered by severity descending.

### Verdict Criteria

- **APPROVED**: No critical or high findings.
- **APPROVED_WITH_CONDITIONS**: No critical; straightforward high findings with listed conditions.
- **CHANGES_REQUIRED**: Has critical findings or compounding high findings.
- **REJECTED**: Fundamental approach issues requiring re-planning.

### Severity Decision Criteria (ordered)

1. Data loss / security breach / full outage -> CRITICAL.
2. Production failures under normal conditions -> HIGH.
3. Failures under realistic edge cases or degradation over time -> MEDIUM.
4. Code quality with no runtime impact -> LOW.
5. Suggestion or positive observation -> INFO.

When uncertain between adjacent levels, choose the higher severity.

### Categories

correctness, security, performance, reliability, maintainability, compatibility.

## Source Map

| Topic                                                 | File                 |
| ----------------------------------------------------- | -------------------- |
| Full report template, writing rules, verdict criteria | `report-template.md` |
| Severity definitions with examples, decision criteria | `severity-levels.md` |

## Maintenance Notes

- Field labels and status values must stay exact for downstream agent parsing.
- Severity model is shared with `verdict-model.md` in the orchestration directory.
