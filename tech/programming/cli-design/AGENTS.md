---
digest-of: tech/programming/cli-design
last-synced: 2026-05-27
source-files:
  - README.md
  - 00-architecture.md
  - 01-logging-and-output.md
  - 02-error-messages.md
  - 03-config-precedence.md
  - 04-coding-style-rust-zig.md
  - 05-designing-for-llm-agents.md
  - 07-naming-and-docs.md
  - 09-reference-projects.md
  - 99-checklist.md
token-estimate: 2800
---

# AGENTS

## Scope

Language-agnostic CLI design canon: architecture, logging, errors, config, coding style, LLM-agent
design, naming, reference projects, and a pre-ship checklist. Language-specific implementations live
in `tech/languages/<lang>/cli-spec/`.

## Key Points

### Architecture (00)

- Split parse-shape (CLI parser structs) from runtime-shape (domain types). Projection happens once
  at the top of each handler.
- One `AppContext` built in `main`, passed by reference. Holds config, paths, UI, runtime handle,
  clock. No globals.
- Directory roles: `cli/` (parse-shape), `commands/` (handlers), `domain/` (pure types, no I/O),
  `adapters/` (external I/O), `services/` (optional shared orchestration), `config/`, `ui/` (only
  place that prints), `util/`.
- Four-edit rule for subcommands: `cli/<name>`, `cli/root`, `commands/<name>`, `main` dispatch.
- Single crate by default; workspace only at ~8k LOC or when a real second consumer appears.

### Logging and Output (01)

- Two layers: user-UX (stdout=data, stderr=UX) and program-logs (file at
  `$XDG_STATE_HOME/<app>/<app>.log`).
- Default log to file in structured `key=value` or JSON, no ANSI. Terminal mirror is opt-in.
- Verbosity: none=warn, `-v`=info, `-vv`=debug, `-vvv`=trace.
- Respect `NO_COLOR`/`FORCE_COLOR`; detect TTY. No print outside `ui/`.

### Error Messages (02)

- Four-part anatomy: what, where, why, hint.
- Stable `err.kind` per variant (machine-matchable, never rename).
- BSD sysexits exit codes (64=usage, 65=data, 66=noinput, 69=unavailable, 70=software, 74=ioerr,
  78=config). No catch-all `1`.
- Per-layer typed errors aggregated at top-level `AppError`.

### Config Precedence (03)

- `CLI > env > project file > user file > defaults` for every key.
- XDG paths for config/state/cache/data. Never `~/.<app>/`.
- Loader tracks per-key source provenance. Unknown keys fail loudly.
- `--print-config` subcommand for debugging.

### Coding Style (04)

- Explicit errors; parse don't validate; newtypes for domain primitives.
- Composition over inheritance; free functions when no state.
- Constructor placement: assembly belongs on the produced type.
- Files <=400 LOC. Comments say why, not what. Module headers state purpose and non-purpose.
- Strict lints project-wide; per-line allow only with justification.

### LLM Agent Design (05)

- Default path: CLI + thin Skill wrapper. MCP only for stateful/auth/multi-tenant needs.
- Three-layer model: CLI (mechanism), SKILL.md (playbook), AGENTS.md (constitution).
- Every output is a prompt: include affected IDs and next-command suggestions.
- `--help` is documentation; `--json` everywhere; `doctor` command for health checks.
- Verb-noun structure mirroring kubectl/docker/gh. Familiar flag names (`--dry-run`, `--force`,
  `--yes`).
- Paginate lists by default. Deterministic and idempotent operations.

### Naming and Docs (07)

- Visibility defaults to least-public. `pub(crate)` before `pub`.
- `<Verb>Args` (parse-shape), `<Verb>Request` (runtime), `<Layer>Error`, concept-name newtypes.
- `--help` is generated from parser, not hand-authored. Narrative goes in intro/epilog hooks.
- Module headers: "what it is, what it isn't."

### Reference Projects (09)

- Ten patterns from real CLIs: single-crate, lib+bin, domain-crates, client+server+common, plugin
  ABI, uniform exec(), focused error+ui modules, options/output split, context+modules,
  dependency-direction workspace.

### Checklist (99)

- Pre-ship sanity check across architecture, logging, errors, config, coding style, LLM agents,
  naming, testing, regression safeguards, CI, and wrapper specifics.

## Source Map

| Topic                                             | File                             |
| ------------------------------------------------- | -------------------------------- |
| Directory layout, parse/runtime shape, AppContext | `00-architecture.md`             |
| Two-layer logging, log schema, channel matrix     | `01-logging-and-output.md`       |
| Error anatomy, sysexits, error layering           | `02-error-messages.md`           |
| 5-layer config merge, XDG, provenance             | `03-config-precedence.md`        |
| 18 coding-style rules                             | `04-coding-style-rust-zig.md`    |
| CLI+Skill+AGENTS.md model, agent-facing patterns  | `05-designing-for-llm-agents.md` |
| Visibility, naming tables, help generation, docs  | `07-naming-and-docs.md`          |
| Organizational patterns from 12 CLIs              | `09-reference-projects.md`       |
| Pre-ship checklist                                | `99-checklist.md`                |

## Maintenance Notes

- Chapters 06 and 08 are subdirectories not included in this digest; load them directly when
  reviewing wrapper design or testing.
- Language-specific specs (`rust/cli-spec/`, `python/cli-spec/`, `bash/cli-spec/`) apply these
  principles to concrete ecosystems.
- Regenerate when any chapter file changes or new chapters are added.
