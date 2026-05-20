# 01 — Logging & Output

Every CLI emits two distinct streams of information. Conflating them is the root cause of unreadable
terminals, broken pipes, and unusable log files. This chapter draws the line.

## The two layers

| Layer               | Audience                                               | Destination (default)                                       | Format                                                   | When written                                                  |
| ------------------- | ------------------------------------------------------ | ----------------------------------------------------------- | -------------------------------------------------------- | ------------------------------------------------------------- |
| **1. User-UX**      | Human at a terminal (or a downstream pipe consumer)    | `stdout` for results · `stderr` for prompts/progress/errors | Colored, formatted, tables, prompts                      | Always                                                        |
| **2. Program-logs** | Developer, LLM coding agent, ops debugging post-mortem | `$XDG_STATE_HOME/<app>/<app>.log` (rotating)                | Structured `key=value` (or `--log-format=json`), no ANSI | Always (file); on-terminal only with `--log-stderr` or `-vv+` |

Why split them:

- **Different consumers**: a user wants `"3 widgets created"`; an LLM debugging a failed run wants
  `level=info op=widget.create id=abc-123 status=ok ms=12`.
- **Different reliability**: terminal output can be redirected mid-pipeline; logs must survive even
  when the user did `2>/dev/null`.
- **Different retention**: terminal output is ephemeral; logs are forensic evidence after the fact.
- **Different formats**: tables and colors corrupt logs when grep'd; structured records overwhelm
  humans on a TTY.

Rule of thumb: **if a human reads it once, it's user-UX. If a tool or developer reads it later, it's
program-logs.**

---

## Layer 1 — User-UX

### Stream discipline

- `stdout` = **the result**. The data a shell pipe expects. Whatever `--format` produces. Nothing
  else.
- `stderr` = **everything else**: prompts, progress bars, status messages, error reports, warnings.
- Anything mixing the two breaks `<cmd> | jq`, `<cmd> > out.txt`, `<cmd> | xargs`.

```sh
# Good — stdout is clean JSON, stderr shows progress
app widget list --format json 2>/dev/null | jq '.[] | .id'

# Bad — progress messages corrupt the pipe
[Loading config…] [...] [{"id":"a"},{"id":"b"}]
```

### Output formats

Expose a `--format` flag with at least `text` (default, human-pretty) and `json` (machine-readable).
Add `yaml` / `table` / `tsv` as needed.

| Format           | Use case                                               |
| ---------------- | ------------------------------------------------------ |
| `text` (default) | Interactive humans. Color, alignment, headers.         |
| `json`           | Scripting, agents, CI. Newline-delimited if streaming. |
| `yaml`           | Humans who want machine-readable.                      |
| `table`          | Wide tabular output for humans.                        |
| `tsv` / `csv`    | Spreadsheets, classic Unix pipes.                      |

If the audience is genuinely interactive, `text` is OK to default to. If your CLI is most often
piped, default to `json` and use `--format text` as the opt-in.

### Color

Respect the three established conventions. Precedence: **NO_COLOR > FORCE_COLOR (or CLICOLOR_FORCE)

> isatty(stdout) check > CLICOLOR**.

| Variable                           | Effect                                  |
| ---------------------------------- | --------------------------------------- |
| `NO_COLOR` (any non-empty value)   | Disable color absolutely.               |
| `FORCE_COLOR` / `CLICOLOR_FORCE`   | Force color even when piped.            |
| `CLICOLOR=0`                       | Disable color (weaker than `NO_COLOR`). |
| `CLICOLOR=1` (default)             | Color when output is a TTY.             |
| `--color {auto,always,never}` flag | Per-invocation override; wins over env. |

Default: `auto` — color when `stdout` is a TTY, off otherwise. Detect via `isatty(1)`. Never emit
ANSI escapes into a log file or a non-TTY stream by accident.

References: [NO_COLOR.org](https://no-color.org/), [force-color.org](https://force-color.org/),
[Indicating CLI color preference (gist)](https://gist.github.com/scop/4d5902b98f0503abec3fcbb00b38aec3).

### Tables, progress, prompts

Pick one library per concern; use it consistently.

| Concern             | Rust                     | Python                       | Bash              |
| ------------------- | ------------------------ | ---------------------------- | ----------------- |
| Tables              | `comfy-table`, `tabled`  | `rich`, `tabulate`           | `column -t`       |
| Progress / spinners | `indicatif`              | `rich.progress`, `tqdm`      | `pv`, custom `\r` |
| Prompts             | `inquire`, `dialoguer`   | `questionary`, `rich.prompt` | `read`            |
| Colors              | `anstream`, `owo-colors` | `rich`, `colorama`           | `tput`, raw ANSI  |

Progress and prompts go to `stderr`, never `stdout`. Progress should auto-hide if `stderr` is not a
TTY.

### Non-interactive mode

Always provide a non-interactive escape hatch for every prompt:

- `--yes` / `-y` — auto-confirm all yes/no prompts.
- `--non-interactive` — fail loudly instead of prompting; pairs with explicit flags for required
  inputs.
- Detect `stdin` is not a TTY → switch to non-interactive automatically and fail rather than
  silently hang.

### Anti-patterns

- `println!`/`echo` scattered across the codebase. Centralize in one `ui/` module (or `ui` library
  boundary). It's grep-able and it's a CI lint.
- Mixing log records (`[INFO 12:34:56]`) into stdout. Use the program-logs layer for that.
- Multi-line errors with stack traces dumped on stdout. Stack traces → program-logs (verbose mode),
  short message → stderr.
- ANSI escapes in piped output. Detect TTY; respect `NO_COLOR`.
- Color-by-default in CI. CI rarely sets `NO_COLOR`; sniff `CI=true` or `GITHUB_ACTIONS=true` and
  default to no color (or to FORCE_COLOR if the CI renders ANSI, e.g. GitHub Actions does).
- Asking interactive confirmation in a script that piped stdin from `/dev/null`. Detect and fail
  with a clear message.

---

## Layer 2 — Program-logs

This is the new contract: every CLI writes a forensic log to a file by default, in a format that
LLMs and humans can both read. The terminal is no longer the primary log destination — the file is.

### Default destination

```
$XDG_STATE_HOME/<app>/<app>.log
```

with `$XDG_STATE_HOME` defaulting to `~/.local/state` per the
[XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/index.html).
State home (not data home, not cache home) is the right XDG dir for logs: "actions history (logs,
history, recently used files)".

Rotation: size-based, e.g. 10 MB × 5 files (`<app>.log`, `<app>.log.1`, … `<app>.log.4`). Pick
reasonable defaults; let users override via config.

The destination is configurable in precedence order (low → high):

1. Built-in default: `$XDG_STATE_HOME/<app>/<app>.log`
1. Config file: `[logging] file = "/path/to.log"`
1. Env var: `<APP>_LOG_FILE=/path/to.log` (or `<APP>_LOG_DIR=/path/to/dir`)
1. CLI flag: `--log-file /path/to.log`

Disable entirely with `--no-log` (writes nowhere).

### When to mirror to the terminal

By default: **the log file is the only destination**. The terminal stays clean for user-UX output.

Mirror to `stderr` when:

- `--log-stderr` flag is passed (explicit user opt-in).
- `--verbose` / `-v` / `-vv` / `-vvv` is passed _and_ the policy is "verbose implies terminal logs".
  Document this.
- `<APP>_LOG_STDERR=1` is set.

If both file and stderr are active, **emit identical records to both**. Different formats per
destination is a debugging trap — when a user pastes their terminal output into a bug report, you
want it to match what's on disk.

### Verbosity flags

Standard convention:

| Flag             | Level filter      | Notes                                           |
| ---------------- | ----------------- | ----------------------------------------------- |
| (none)           | `warn` and above  | Default. Quiet.                                 |
| `-v`             | `info` and above  | "Tell me what's happening."                     |
| `-vv`            | `debug` and above | "Tell me a lot."                                |
| `-vvv`           | `trace` and above | Full firehose; hot loops.                       |
| `--quiet` / `-q` | `error` only      | Suppress warnings.                              |
| `--silent`       | nothing           | Logs still go to file; just no terminal mirror. |

Env var override (per language convention, e.g. `RUST_LOG`, `PYTHONLOGLEVEL`). The env var should
accept directive syntax (e.g. `RUST_LOG=app=debug,hyper=warn`) so users can scope verbosity to a
module.

**Do not invent app-specific log env vars** when an ecosystem convention exists. Users have muscle
memory for `RUST_LOG`. Reuse it.

### Record format

Every record is **one line**, structured, parseable by both grep and an LLM.

Two emission modes, same field schema:

**`key=value` (default, grep-friendly):**

```
ts=2026-05-18T10:23:45.123Z level=info target=app::widget op=create id=abc-123 status=ok dur_ms=12
```

**`--log-format json` (tool-friendly, newline-delimited):**

```
{"ts":"2026-05-18T10:23:45.123Z","level":"info","target":"app::widget","op":"create","id":"abc-123","status":"ok","dur_ms":12}
```

### Required fields

| Field    | Type                                | Notes                                                                                            |
| -------- | ----------------------------------- | ------------------------------------------------------------------------------------------------ |
| `ts`     | ISO-8601 UTC, millisecond precision | Stable, sortable. Not the local TZ.                                                              |
| `level`  | `error\|warn\|info\|debug\|trace`   | Lowercase.                                                                                       |
| `target` | module path                         | E.g. `app::widget::sync`. Matches log-filter syntax.                                             |
| `msg`    | short human string                  | Required only when there's no structured `op` field that conveys the intent. Keep it ≤ 80 chars. |

### Optional / operation-specific fields

Use **short, stable field names**. Document the schema in your README. LLMs benefit from convention
more than from verbosity.

| Field                  | Use                                                                                                    |
| ---------------------- | ------------------------------------------------------------------------------------------------------ |
| `op`                   | Operation name, e.g. `widget.create`, `git.fetch`. Prefer this over a freeform `msg`.                  |
| `id`, `path`, `url`, … | Operation-specific subject.                                                                            |
| `status`               | `ok` / `error` / `skip` / `noop`.                                                                      |
| `dur_ms`               | Duration in milliseconds (integer).                                                                    |
| `err.kind`             | Stable error code (e.g. `ConfigNotFound`, `Timeout`). See [02 — Error Messages](02-error-messages.md). |
| `err.msg`              | Human-readable error message.                                                                          |
| `span`                 | Span/trace ID when spans are in use.                                                                   |
| `parent`               | Parent span ID.                                                                                        |

Quote any value containing spaces or `=`. Escape with the format's standard rules (logfmt for
key=value, JSON for the other).

### LLM-token-friendly principles

Inspired by the practices emerging around AI agents debugging from logs
([Observability for AI Agents](https://mightybot.ai/blog/observability-for-ai-agents/),
[Logging vs LLM Observability in 2026](https://futureagi.com/blog/logging-vs-llm-observability-2026)):

1. **One record = one line.** Multi-line records cost tokens and break grep.
1. **Short, stable field names.** `dur_ms` beats `duration_milliseconds`. Don't rename fields
   between versions — LLMs and tools memorize them.
1. **Stable schema, optional fields.** A record can omit fields it doesn't need, but the names it
   does emit must match the documented schema.
1. **Don't repeat headers.** No banner lines, no per-command "===" separators. The timestamp on each
   record is enough.
1. **Span entry/exit collapsed.** If you use tracing spans, emit one record per span at _exit_ (with
   `dur_ms`), not separate `enter` + `exit` records. Halves the token count.
1. **Errors as fields, not prose.** `err.kind=ConfigNotFound err.path=/etc/app.toml` beats
   `"Could not load config from /etc/app.toml because the file did not exist"`. The structured form
   takes fewer tokens and is grep-able.
1. **No ANSI escapes in the file.** Ever. They double the byte count and confuse parsers.
1. **No multi-line stack traces in the default format.** When trace output is required, gate it
   behind `-vvv` and a separate `err.trace` field whose value is a single escaped line (or a pointer
   to a file).

### Channels matrix

What goes where, by event class:

| Event                     | stdout | stderr        | log-file            | log-stderr (`-vv` etc.) |
| ------------------------- | ------ | ------------- | ------------------- | ----------------------- |
| Command result (data)     | ✅     | —             | —                   | —                       |
| User prompt               | —      | ✅            | —                   | —                       |
| Progress bar / spinner    | —      | ✅ (TTY only) | —                   | —                       |
| Warning the user must see | —      | ✅            | ✅                  | ✅                      |
| Error reported to user    | —      | ✅            | ✅                  | ✅                      |
| Info-level operation log  | —      | —             | ✅                  | ✅                      |
| Debug-level call trace    | —      | —             | ✅                  | ✅                      |
| Trace-level firehose      | —      | —             | ✅ (only if `-vvv`) | ✅                      |

### Anti-patterns

- **Default-verbose**: forces every user to add `--quiet`. Start at `warn`.
- **App-specific env var when a convention exists** (`MYAPP_LOG` instead of `RUST_LOG`). Reuse the
  ecosystem's.
- **Different format on stderr vs file**: makes bug reports useless. Same records, both places.
- **ANSI colors in log files**: makes the file unreadable in `less` and bloats it.
- **Multi-line records**: breaks grep and bloats token usage for agents.
- **Log mixed into stdout**: breaks piped consumers.
- **Per-command log file**: hard to find later. One file per app, rotated.
- **Logging to a hard-coded `~/.<app>/log`**: violates XDG, surprises users.
- **Tracing every `if` branch at `info`**: signal-to-noise collapses. Reserve `info` for top-level
  operations.

---

## Implementation pointers

Language-specific guides live alongside the matching language spec:

- **Rust**:
  [`tech/languages/rust/cli-spec/04-logging.md`](../../languages/rust/cli-spec/04-logging.md) —
  `tracing` + `tracing-subscriber` + `tracing-appender` for the file sink. JSON via
  `tracing-subscriber::fmt::layer().json()`. Color via `anstream` / `owo-colors`.
- **Python**:
  [`tech/languages/python/cli-spec/typer-patterns.md`](../../languages/python/cli-spec/typer-patterns.md)
  — `structlog` or `loguru` for structured records; `rich` for the user-UX layer.
- **Bash**:
  [`tech/languages/bash/cli-spec/bash-cli-project-specs.md`](../../languages/bash/cli-spec/bash-cli-project-specs.md)
  — `tput` for color, `printf` for structured records, `logger` for syslog routing.

## See also

- [00 — Architecture](00-architecture.md): where the logging-init helper lives and how it's wired
  through `AppContext`.
- [02 — Error Messages](02-error-messages.md): how errors map to log records (`err.kind`, `err.msg`)
  and to exit codes.
- [03 — Config Precedence](03-config-precedence.md): how the log destination and level are loaded
  from CLI/env/file/default.
- [05 — Designing for LLM Agents](05-designing-for-llm-agents.md): why the program-log schema
  matters for agent-assisted debugging.

## References

- [XDG Base Directory Specification](https://specifications.freedesktop.org/basedir/latest/index.html)
- [NO_COLOR](https://no-color.org/) · [FORCE_COLOR](https://force-color.org/) ·
  [Indicating CLI color preference](https://gist.github.com/scop/4d5902b98f0503abec3fcbb00b38aec3)
- [logfmt format](https://brandur.org/logfmt) — origin of key=value structured logging
- [Twelve-Factor App: Logs](https://12factor.net/logs) — for context on stdout-as-log-stream (the
  CLI default deliberately diverges)
- [Observability for AI Agents](https://mightybot.ai/blog/observability-for-ai-agents/)
- [Logging vs LLM Observability in 2026](https://futureagi.com/blog/logging-vs-llm-observability-2026)
