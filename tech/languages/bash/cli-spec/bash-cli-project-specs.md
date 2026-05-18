# Bash CLI Project — Specs Overview

> Prerequisite: [General CLI principles](../../../programming/cli-design/) for architecture, logging, errors, config, and coding-style rules that apply to every CLI regardless of language.
>
> For the **agent-facing surface** (`--help`, `--json`, output-as-prompt, error shape, `doctor`, exit-code conventions, config precedence, dry-run discipline, skill wrapper, evals), see [Designing for LLM Coding Agents](../../../programming/cli-design/05-designing-for-llm-agents.md). Rules there apply to this stack; they are not duplicated here.

Bash-specific conventions for building a CLI tool: layout, entry point,
strict-mode caveats, module organisation, testing, linting, install, and
distribution.

---

## Directory Structure

```text
my-cli/
├── bin/
│   └── my-cli                    # thin shim → loader → main "$@"
├── lib/
│   ├── loader.sh                 # source-on-dispatch
│   ├── core.sh                   # main(), global flags, dispatch
│   ├── helpers.sh                # __log_err, __require, etc. (eager)
│   ├── commands/
│   │   ├── cmd_foo.sh            # defines mycli::cmd::foo
│   │   └── cmd_bar.sh
│   └── functions/
│       ├── fn_parse_args.sh      # defines mycli::fn::parse_args
│       └── fn_render_table.sh
├── completions/
│   └── my-cli.bash
├── man/
│   └── my-cli.1.scd              # scdoc source → compiled to .1
├── test/
│   ├── test_helper/
│   │   ├── bats-support/         # submodule
│   │   ├── bats-assert/          # submodule
│   │   ├── bats-file/            # submodule
│   │   └── common-setup.bash
│   └── cmd_foo.bats
├── .shellcheckrc
├── .editorconfig
├── Makefile
├── install.sh
└── uninstall.sh
```

One public function per file; filename encodes the function name; `lib/`
holds shared machinery. Same shape as a well-organised interactive-shell
package, applied to a standalone CLI.

---

## Entry Point (`bin/my-cli`)

```bash
#!/usr/bin/env bash
set -euo pipefail
shopt -s inherit_errexit 2>/dev/null || true   # bash 4.4+

# Resolve script path through symlinks (stow, make install, etc.)
src="${BASH_SOURCE[0]}"
while [[ -L "$src" ]]; do
  dir="$(cd -P "$(dirname "$src")" && pwd)"
  src="$(readlink "$src")"
  [[ "$src" != /* ]] && src="$dir/$src"
done
readonly SCRIPT_DIR="$(cd -P "$(dirname "$src")" && pwd)"
readonly LIB_DIR="${SCRIPT_DIR}/../lib"

# shellcheck source=../lib/helpers.sh
source "${LIB_DIR}/helpers.sh"
# shellcheck source=../lib/loader.sh
source "${LIB_DIR}/loader.sh"
# shellcheck source=../lib/core.sh
source "${LIB_DIR}/core.sh"

mycli::main "$@"
```

- Shim only — no logic in `bin/`.
- Symlink resolution matters: `stow`, `make install`, and `ln -s` in
  `~/.local/bin` all break the naive `dirname "${BASH_SOURCE[0]}"` idiom.
- `inherit_errexit` fixes the silent-`set -e`-disables-in-subshells
  pitfall; guarded for pre-4.4 bash.

---

## Strict Mode — Default, Not Gospel

```bash
set -euo pipefail
shopt -s inherit_errexit failglob nullglob lastpipe
```

Treat as the default. Known limits:

- `set -e` is disabled inside command substitutions, `if`/`&&`/`||`
  chains, and `local var=$(...)` (the `local` masks the inner exit).
  See [ShellCheck SC2310/SC2311](https://www.shellcheck.net/wiki/SC2310).
- `set -o pipefail` can turn a benign SIGPIPE (producer killed by a
  short-circuiting `grep -q`) into a failure.
- `set -u` overlaps with shellcheck; keep it for defence-in-depth.
- **Do not set `IFS=$'\n\t'` globally.** It changes global word-splitting
  semantics and breaks sourced code that assumes default IFS. Quote
  everything (`"$@"`, `"${arr[@]}"`) and use arrays; that solves the real
  problem without global side effects.
  (Critique: [Gondža](https://olivergondza.github.io/2019/10/01/bash-strict-mode.html),
  [BashFAQ/105](https://mywiki.wooledge.org/BashFAQ/105).)

For load-bearing logic, prefer an explicit `|| return` / `trap '...' ERR`
over trusting `set -e` implicitly.

---

## Module Layout: One Function per File

This is the core organisational pattern. Makes the code easy for humans
and LLMs to reason about, and keeps startup O(1) via lazy sourcing.

### Naming

| Path                     | Defines                         | Visibility |
|--------------------------|---------------------------------|------------|
| `lib/commands/cmd_<n>.sh`| `mycli::cmd::<n>`               | public     |
| `lib/functions/fn_<n>.sh`| `mycli::fn::<n>`                | public     |
| `lib/helpers.sh`         | `__log_err`, `__require`, …     | shared     |
| (any file) `__<n>`       | private helper, same file       | private    |

- **One public function per file.** Filename mirrors the function name
  so the dispatcher can derive it without a lookup table.
- `__`-prefix marks private helpers (sourced alongside, not exported).
- Every `.sh` under `lib/` starts with `# shellcheck shell=bash` (no
  shebang — these are sourced, not executed).

### Self-describing files

Each file documents itself on line 2 with a sentinel the help/man
generator can harvest:

```bash
# shellcheck shell=bash
: 'desc: Dispatch a message to a roost.'

mycli::cmd::dispatch() {
  local -r to="$1"; shift
  # ...
}
```

The `desc:` line is lazy-loaded — costs nothing at startup, parseable by a
trivial `grep`-driven help generator on demand.

### Loader (source on dispatch)

`lib/loader.sh`:

```bash
# shellcheck shell=bash
mycli::loader::dispatch() {
  local sub="$1"; shift
  local path="${LIB_DIR}/commands/cmd_${sub}.sh"
  if [[ ! -r "$path" ]]; then
    mycli::helpers::die 2 "unknown command: ${sub}"
  fi
  # shellcheck source=/dev/null
  source "$path"
  "mycli::cmd::${sub}" "$@"
}
```

Startup stays O(1) regardless of command count — commands load only
when invoked. This is the same shape as a Bash autoloader: source on
first use, cache nothing.

### Host / env overlays

`${XDG_CONFIG_HOME:-$HOME/.config}/my-cli/conf.d/*.sh` sourced last so
users override defaults without forking. Same idea as per-host overlays
in interactive Bash startup files: drop-in files in a known directory,
sourced in lexical order after the built-in defaults.

---

## ShellCheck Discipline

`.shellcheckrc` at repo root:

```text
external-sources=true
source-path=SCRIPTDIR
source-path=SCRIPTDIR/lib
shell=bash
```

Rules:

- Every cross-file `source` gets an explicit `# shellcheck source=<path>`
  directive (or rely on `source-path=` above). Without it, shellcheck
  silently skips the file and misses half the real bugs.
- `# shellcheck disable=SC<n>` must carry a one-line justification
  comment; unexplained disables fail review.
- Reference: [shellcheck directives](https://github.com/koalaman/shellcheck/wiki/Directive).

---

## Errors, Signals, Temp Files

```bash
tmpdir="$(mktemp -d)" || exit 1
trap 'rm -rf "$tmpdir"' EXIT
trap 'rm -rf "$tmpdir"; exit 130' INT
trap 'rm -rf "$tmpdir"; exit 143' TERM
```

- Single-quoted trap bodies (variables expand at trap time, not
  registration time).
- `mktemp -d` always with `|| exit 1`, always paired with an `EXIT` trap.
- SIGINT exits `130`, SIGTERM `143` (128 + signal number).
- `printf '%s\n'` over `echo` (portable across bash versions).
- Logs to stderr, data to stdout. See agent-design doc §2.6 for why this
  matters for piping.

Exit-code conventions (`0`/`1`/`2` + `sysexits.h` ranges + `128+N`) are
documented in
[Designing for LLM Coding Agents](../../../programming/cli-design/05-designing-for-llm-agents.md)
§2.4 and in [General — Error Messages](../../../programming/cli-design/02-error-messages.md) —
the bash side just has to implement them consistently.

---

## Testing (bats-core)

> Prerequisite: [General principles — Testing Strategy](../../../programming/cli-design/08-testing-strategy.md) for the pyramid, tier table, isolation rules, and what to mock. This section is the bats-core implementation.

Layout:

```text
test/
├── test_helper/
│   ├── bats-support/        # git submodule
│   ├── bats-assert/         # git submodule
│   ├── bats-file/           # git submodule
│   └── common-setup.bash
└── cmd_foo.bats
```

`test/test_helper/common-setup.bash`:

```bash
_common_setup() {
  load 'bats-support/load'
  load 'bats-assert/load'
  load 'bats-file/load'
  PATH="${BATS_TEST_DIRNAME}/../bin:$PATH"
}
```

`test/cmd_foo.bats`:

```bash
setup() {
  load 'test_helper/common-setup'
  _common_setup
}

@test "foo --bar outputs expected" {
  run my-cli foo --bar
  assert_success
  assert_output "expected"
}
```

Reference: [bats-core tutorial](https://bats-core.readthedocs.io/en/stable/tutorial.html).

---

## Linting / Formatting

All checks run through **pre-commit** (see root
[[CLAUDE]] § "Linting & Validation" for the repo-wide policy):

- [shellcheck](https://www.shellcheck.net/) — static analysis.
- [shfmt](https://github.com/mvdan/sh) — formatter. Canonical flags:
  `shfmt -i 2 -ci -bn -s`.
- Do not invoke linters directly; add them to `.pre-commit-config.yaml`.

---

## Install / XDG Paths

`install.sh` honours both `PREFIX` (system) and XDG (user):

| Artifact          | System                                              | User                                                      |
|-------------------|-----------------------------------------------------|-----------------------------------------------------------|
| binary            | `$PREFIX/bin/`                                      | `$HOME/.local/bin/`                                       |
| lib tree          | `$PREFIX/lib/my-cli/`                               | `$HOME/.local/lib/my-cli/`                                |
| bash completion   | `$(pkg-config --variable=completionsdir bash-completion)` | `${XDG_DATA_HOME:-$HOME/.local/share}/bash-completion/completions/` |
| man page          | `$PREFIX/share/man/man1/`                           | `${XDG_DATA_HOME:-$HOME/.local/share}/man/man1/`          |
| config            | `/etc/my-cli/config.toml`                           | `${XDG_CONFIG_HOME:-$HOME/.config}/my-cli/config.toml`    |
| state             | `/var/lib/my-cli/`                                  | `${XDG_STATE_HOME:-$HOME/.local/state}/my-cli/`           |
| cache             | `/var/cache/my-cli/`                                | `${XDG_CACHE_HOME:-$HOME/.cache}/my-cli/`                 |

- Detect root vs user install via `[[ $EUID -eq 0 ]]`.
- `uninstall.sh` reads a manifest written by `install.sh` at install time.
- Reference: [XDG Base Directory spec](https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html).

`Makefile` wraps `install` / `uninstall` / `test` / `lint` / `man`.

Config precedence: see [`cli-design/03-config-precedence.md`](../../../programming/cli-design/03-config-precedence.md) for the canonical 5-layer ladder. Secret handling and missing-config error shape: see [`cli-design/05-designing-for-llm-agents.md §2.9`](../../../programming/cli-design/05-designing-for-llm-agents.md#29-config-via-env--file-never-interactive-prompts).

---

## Man Page

Prefer [scdoc](https://git.sr.ht/~sircmpwn/scdoc) over hand-rolled
`.1` or pandoc — tiny C dep, markdown-ish source, deterministic output:

```text
man/my-cli.1.scd   →   man/my-cli.1   (built by Makefile)
```

---

## Distribution

| Approach                    | Use case                                                      |
|-----------------------------|---------------------------------------------------------------|
| Multi-file + `install.sh`   | Default for this repo's tools; fallback everywhere            |
| [bashly](https://github.com/bashly-framework/bashly) bundle | Single-file build for `curl \| sh` installers |
| Homebrew formula            | Users on macOS / linuxbrew                                    |
| AUR `PKGBUILD`              | Arch users                                                    |
| Nix flake                   | Reproducible dev shells, pinned toolchain                     |
| `.deb` via `dh_make`        | Debian/Ubuntu packaging                                       |

Avoid `shc` (obfuscating C-wrapper, not a bundler — wrong tool).

---

## CI

Minimum viable GitHub Actions matrix:

```yaml
jobs:
  check:
    strategy:
      matrix:
        bash: ['4.4', '5.0', '5.2']
    steps:
      - uses: actions/checkout@v4
        with: { submodules: recursive }
      - run: shellcheck -x bin/* lib/**/*.sh
      - run: shfmt -d -i 2 -ci -bn -s bin lib
      - run: bats test/
```

---

## Non-Negotiables

1. `set -euo pipefail` + `shopt -s inherit_errexit` (with documented caveats).
2. shellcheck clean; `source=`/`source-path=` directives wired up.
3. shfmt clean (`-i 2 -ci -bn -s`), config checked in.
4. Namespaced functions (`mycli::<ns>::<fn>`), one public function per file.
5. XDG-aware, `PREFIX`-overridable installer; uninstall via manifest.
6. bats-core tests under `test/` with `test_helper/` submodules.
7. `trap ... EXIT INT TERM` cleanup for any script that creates temp state.
8. `printf` over `echo`; stderr for logs; stdout is parseable data only.
9. Agent-facing surface per
   [Designing for LLM Coding Agents](../../../programming/cli-design/05-designing-for-llm-agents.md)
   (`--help`, `--json`, error shape, `doctor`, dry-run, exit codes).
