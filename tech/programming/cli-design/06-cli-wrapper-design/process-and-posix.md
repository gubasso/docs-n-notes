# Wrapper Design — Process & POSIX

> **See also.** The sibling chapter [Typing & Validation](./typing-and-validation.md) covers the *implementation* side: how to model the wrapped CLI's domain as typed structures, separate build from execution, and avoid scattered `.arg("--flag")` calls. Read both — this one is about *invoking* the subprocess correctly; the sibling is about *building* what you invoke.
>
> This chapter is part of [CLI Wrapper Design](./README.md) under the general [CLI design principles](../README.md).

General-purpose guideline for CLI programs that need to (a) wrap/invoke
another existing CLI command and (b) implement their own specific
options/arguments/flags on top.

A wrapper CLI is itself a Unix utility, so it inherits the full
POSIX/GNU contract. On top of that it has one unique job: be a
*translator and shepherd* for another process. The patterns below are
what the ecosystem (POSIX, GNU, clig.dev, git, cargo, kubectl, gh, env,
sudo, pyenv/asdf/mise) has converged on.

**Single most important principle:** make the wrapper's grammar small
and explicit, keep the wrapped command mostly opaque, and avoid argv
rewriting unless you have a narrow, stable reason. Every other rule
descends from this.

---

## 1. Argv layout & namespace separation

Treat the CLI as having three syntactic zones:

```
mywrap [WRAPPER-OPTS]  <verb|positional>  [--]  [CHILD-ARGS...]
```

- **Wrapper options first, child args last** — POSIX Utility Syntax
  Guideline 9 ("all options should precede operands"). Cargo, git,
  kubectl, docker, env, sudo all do this.
- **`--` is the end-of-options sentinel** (POSIX Guideline 10). The
  parser must stop interpreting flags after `--` and forward the rest
  verbatim. Without it, users cannot pass `-`-prefixed operands to the
  child.
- **Require `--` when there's any ambiguity**; infer only when the
  verb's grammar has an unambiguous command slot
  (`kubectl exec POD -- cmd...`, `mise exec ... -- cmd...`).
- **Avoid future collisions with upstream flags:** use **long-only,
  namespaced** wrapper flags (`--mywrap-trace`); leave short flags to
  the child. If both sides use the same name, namespace yours or move
  it to an env var.

Sources:
- [POSIX Utility Syntax Guidelines](https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html)
- [GNU argument syntax](https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html)
- [Command Line Interface Guidelines (clig.dev)](https://clig.dev/)

---

## 2. Where wrapper config lives — and the merge order

clig.dev / 12-factor precedence ladder (highest wins):

1. Command-line flags
2. Environment variables (`MYWRAP_*` prefix)
3. Project config (`./.mywraprc` or repo file)
4. User config (`$XDG_CONFIG_HOME/mywrap/config.toml`)
5. System config (`/etc/mywrap/...`)
6. Built-in defaults

- Use **XDG Base Directory** paths for config/data/cache.
- Reserve a **single namespaced env prefix** (`MYWRAP_*`); never leak
  it into the child's environment unless the child explicitly expects
  it.
- **Prefer env-var-only** for operationally-global wrapper options
  (debug, log level, alternate child binary, cache dir, profile) —
  keeps argv clean, and argv *is* the contract you forward to the
  child.

Sources:
- [Command Line Interface Guidelines — Configuration](https://clig.dev/)
- [12 Factor CLI Apps — Jeff Dickey](https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46)
- [The Twelve-Factor App — Config](https://12factor.net/config)

---

## 3. Process model — exec vs spawn, signals, exit codes, tty

**Default to `execvp` (process replacement); spawn-and-wait only when
you must.** Every layer added changes signal and TTY semantics.

### exec vs spawn-and-wait

- **`execvp`**: kernel reuses the PID, the child *becomes* the
  process. No signal forwarding to write — the child *is* you. Used by
  `env`, `nice`, `chrt`, simple shims.
- **`fork+exec+wait`**: required for pre/post work, output filtering,
  supervision, exit-code mapping.

### What `exec*` inherits / resets (POSIX)

- Open fds persist unless `FD_CLOEXEC`.
- Environment is passed through (use `execve`/`execle` to override).
- **Signal dispositions:** `SIG_DFL` stays default, `SIG_IGN` stays
  ignored, but **handlers installed are reset to `SIG_DFL` in the new
  image**. Critical: if you spawn (not exec) and install handlers in
  the parent, you must explicitly forward signals.

### Signal forwarding (spawn case)

Forward at minimum:

- **SIGINT, SIGTERM, SIGQUIT, SIGHUP** — terminate intent.
- **SIGTSTP, SIGCONT** — job control.
- **SIGUSR1, SIGUSR2** — many tools use these.
- **SIGWINCH** — terminal resize, mandatory if you allocate a PTY; the
  child cannot relayout without it.

Pattern: install a handler that does `kill(child_pid, signo)` (or
`killpg` for the whole group), then `waitpid` the child and re-raise
the same signal on yourself if the child died from it so your parent
process *also* dies from the signal — this is what `sudo` does and is
what preserves the `128+N` convention upstream.

### Exit-code propagation

Use the shell convention:

- Child exited normally with code N → wrapper exits N.
- Child died from signal N → wrapper exits **128 + N** (SIGINT=2 →
  130, SIGTERM=15 → 143, SIGKILL=9 → 137). Bash documents this; mirror
  it precisely or scripts break.
- Reserve a distinct range for **wrapper-originated** failures (see
  §8) so callers can attribute the error.

### TTY / PTY

- **Inherit** (default): child gets your stdin/stdout/stderr. Works
  for non-interactive use and for interactive children when wrapper
  does no I/O massaging.
- **Allocate a PTY**: required if you're piping/teeing output and the
  child changes behavior on `isatty()` (paginators, color, progress
  bars). If you allocate a PTY you become responsible for
  `setsid`+`TIOCSCTTY` on the child side and `SIGWINCH` propagation on
  the parent side. PTYs change buffering and job-control behavior —
  pay the cost only when you must.

Sources:
- [POSIX execvp](https://pubs.opengroup.org/onlinepubs/9699919799/functions/execvp.html)
- [POSIX wait](https://pubs.opengroup.org/onlinepubs/9699919799/functions/wait.html)
- [Bash exit status](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)
- [veithen.io: SIGTERM propagation in wrappers](https://veithen.io/2014/11/16/sigterm-propagation.html)
- [Baeldung: SIGINT propagation parent/child](https://www.baeldung.com/linux/signal-propagation)
- [R. Koucha: SIGWINCH & PTY handling](http://www.rkoucha.fr/tech_corner/sigwinch.html)
- [Wikipedia: Exit status](https://en.wikipedia.org/wiki/Exit_status)
- [sudo manpage](https://www.sudo.ws/docs/man/sudo.man/)

---

## 4. Resolving the inner binary

Layered lookup, highest priority first:

1. **`$MYWRAP_CHILD_BIN`** — explicit override (single source of truth
   for tests and CI).
2. **Config file** entry (`child_bin = "/opt/foo/bin/foo"`).
3. **`PATH` search** via `execvp` semantics.
4. **Bundled vendor path** if you ship one
   (`$XDG_DATA_HOME/mywrap/bin/foo`).

### Recursion guard (shim pattern)

If your wrapper is installed under the **same name as the inner tool**
(pyenv/rbenv/asdf shim pattern), you *must* prevent infinite re-entry.
Three proven techniques:

- **Strip yourself from PATH** before resolving — what `pyenv-which`
  does.
- **Marker env var** (`MYWRAP_REENTRY=1`) — refuse to act as a wrapper
  if you see it already set; instead, fall through to the real binary
  or fail loudly.
- **Inode/path self-check** — compare resolved path against
  `current_exe().canonicalize()` and refuse if equal.

Also: resolve **once**, log the resolved absolute path under
`--mywrap-trace`, and fail fast with a clear error if missing (exit
**127** — *command not found* — to match shell convention) or not
executable (exit **126**).

Sources:
- [Deep dive: how pyenv works (shim pattern)](https://www.mungingdata.com/python/how-pyenv-works-shims/)
- [pyenv shim interception pattern (readoss)](https://readoss.com/en/pyenv/pyenv/shim-interception-pattern-pyenv-hijacks-python-commands)
- [pyenv infinite-loop failure mode (issue #2696)](https://github.com/pyenv/pyenv/issues/2696)
- [mise vs asdf](https://mac.install.guide/mise/mise-vs-asdf)

---

## 5. Subcommand / plugin namespacing

Four well-tested models — pick one (and combine with a reserved-verb
namespace):

| Model | Examples | How it works | When to use |
|---|---|---|---|
| **PATH dispatch by prefix** | `git foo` → `git-foo` | Wrapper looks up `$PROG-$verb` on PATH and execs | Open, decentralized plugin ecosystems. Simplest. |
| **PATH dispatch + longest match** | `kubectl foo bar baz` → tries `kubectl-foo-bar-baz` then `-foo-bar` then `-foo` | Same as git, but greedy on segments; underscores in filename become dashes in command | Hierarchical verb trees |
| **Managed extension registry** | `gh extension install owner/gh-foo` | Wrapper has its own install/list/upgrade for extensions in a private dir | Discoverability + lifecycle management |
| **Reserved-verb namespace** | `mytool self update`, `cargo metadata` | Wrapper-owned verbs grouped under a reserved noun so user/plugin verbs can't collide | Always — combine with one of the above |

**Universal rules these share:**

- Plugins **cannot override built-in verbs** (kubectl explicitly
  forbids it; cargo too).
- The wrapper passes the *original verb* as `argv[1]` to the helper
  (cargo: `cargo foo a b` → `cargo-foo foo a b`). Helpers can
  therefore be invoked standalone or via the wrapper.
- Help delegation: `cargo help foo` invokes `cargo-foo foo --help`.
- A `CARGO`/`KUBECTL_PLUGIN_CURRENT_...` style env var can be exported
  so the plugin can call back into the parent — but kubectl
  deliberately doesn't, to keep plugins decoupled.

Sources:
- [Cargo external tools / custom subcommands](https://doc.rust-lang.org/cargo/reference/external-tools.html)
- [Git: How to integrate new subcommands](https://git.github.io/htmldocs/howto/new-command.html)
- [Kubernetes: Extend kubectl with plugins](https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/)
- [GitHub Docs: Creating GitHub CLI extensions](https://docs.github.com/en/github-cli/github-cli/creating-github-cli-extensions)
- [gh extension manual](https://cli.github.com/manual/gh_extension)

---

## 6. Composition vs translation — the cardinal rule

**Default to verbatim pass-through. Translate only when you must.**

The moment the wrapper parses the inner tool's grammar, you have
coupled to a version of that grammar. Upstream adds a flag → your
rewrite pipeline silently strips or breaks it. Almost every long-lived
wrapper that translates argv ends up chasing its parent.

Genuine reasons to parse-and-rewrite:

- **Inject** a required flag (`--config=/tmp/generated`).
- **Veto** dangerous combinations (security wrappers).
- Expose a **deliberately different UX** (true frontend: `httpie` vs
  `curl`).
- **Normalize** across multiple child versions.

Even then: parse the *minimal subset* (only the flags you must
intercept), and **forward everything else opaque**. Use a **denylist
of flags you claim**, not an allowlist of flags you understand.

---

## 7. UX — help, version, completions, man pages

- **`--help` / `-h`**: print your own help and explain the split with
  examples that include `--`. Offer explicit delegation: `mywrap
  child-help` or `mywrap -- --help`. clig.dev: *"Ignore other flags
  when help is requested."*
- **`--version`**: print *both* — wrapper version *and* resolved child
  path + version. One line that saves hours of bug-report triage.
- **Completions**: ship static `bash`/`zsh`/`fish` for *your* flags;
  defer to the child's completion for child args. Dynamic only when
  you need to enumerate runtime state.
- **Man pages**: `mywrap(1)`, plus `mywrap-VERB(1)` if you have many
  verbs (git's convention).

Sources:
- [Cargo external tools / `cargo help`](https://doc.rust-lang.org/cargo/reference/external-tools.html)
- [git-help docs](https://git-scm.com/docs/git-help)

---

## 8. Failure modes & exit codes

- `0` success.
- `2` shell/getopt usage error (GNU convention).
- **`64–78` `sysexits.h`** (BSD): `EX_USAGE 64`, `EX_DATAERR 65`,
  `EX_NOINPUT 66`, `EX_UNAVAILABLE 69`, `EX_SOFTWARE 70`,
  `EX_OSERR 71`, `EX_IOERR 74`, `EX_NOPERM 77`, `EX_CONFIG 78`.
  **Caveat:** `sysexits.h` is BSD-origin, not POSIX, and not
  universally portable. Use it as *a* convention for structured
  wrapper-side codes, but document your own scheme regardless.
- `126` found but not executable, `127` command not found — match
  shell semantics.
- `128 + N` killed by signal N — preserve from child.

**Range reservation for wrappers**: reserve a distinguishable range
for your *own* errors (config, missing child, bad usage). Anything
outside that range is the child's. Document this in `--help`. That way
callers/scripts can distinguish *who* failed.

When the child binary is missing or not executable: emit a clear
stderr message naming the binary you tried, the `PATH` you searched,
and the override env var; exit `127` (missing) or `126` (not
executable). This matches `/bin/sh` and is what tooling expects.

Sources:
- [sysexits.h(3head) — Linux man page](https://man7.org/linux/man-pages/man3/sysexits.h.3head.html)
- [sysexits — FreeBSD man page](https://man.freebsd.org/cgi/man.cgi?query=sysexits)
- [Bash exit status](https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html)
- [POSIX xargs (127 convention)](https://pubs.opengroup.org/onlinepubs/009695399/utilities/xargs.html)
- [Wikipedia: Exit status](https://en.wikipedia.org/wiki/Exit_status)

---

## 9. Testability

Bake the seams in from day one:

- **Hexagonal port for the exec layer.** Hide `fork/exec/wait` behind
  an interface (`Spawner`). Real impl in prod, in-memory stub in
  tests. Single biggest design payoff.
- **Golden argv tests.** Replace the child with a stub script (or env
  var `MYWRAP_CHILD_BIN=./tests/echo-argv.sh`) that prints its argv as
  JSON. Snapshot the parent → child argv translation for every
  supported invocation. Catches regressions in flag handling
  instantly.
- **Snapshot tests on `--help` and `--version`.** User-facing
  contracts and exercise option-discovery code paths.
- **Signal/exit-code matrix tests.** Stub child sleeps then exits N,
  or sleeps and gets SIGINT; assert wrapper exits N or 128+SIGINT.
- **Config precedence tests.** Table-driven: flag-beats-env-beats-config
  for every overridable option.
- **PATH-resolution / shim tests.** Drop fake binaries into a tmp PATH
  and assert the right one wins; assert recursion guard fires when the
  wrapper is `argv[0]`d as the child.

---

## 10. Anti-patterns — avoid by construction

- **Parsing the full child grammar.** Couples you to a version; every
  upstream release becomes a bug. (See §6.)
- **Greedy flag consumption.** Take only flags on your allowlist;
  forward the rest. Anything else and you will eventually steal a flag
  the child needed.
- **Swallowing the child's exit code.** Always propagate (and respect
  128+N). Never `return 1` because the child returned 17.
- **Mixing wrapper logs into the child's stdout.** stdout is reserved
  for whatever the child writes (and what your callers will pipe).
  Wrapper diagnostics go to **stderr**.
- **Hiding the child's stderr** behind your own progress UI without an
  opt-out. Users debugging the child need raw output.
- **Reimplementing what the child already does.** If `child --json`
  exists, expose it, don't reinvent it.
- **Forgetting `--`.** Without it, users cannot pass `-`-prefixed
  operands to the child.
- **Inheriting the wrapper's environment unfiltered into the child**
  when sensitive (e.g., `MYWRAP_TOKEN`). Scrub your own namespace from
  the child's env unless you intend to expose it.
- **Shim with no recursion guard.** Documented failure mode in pyenv.
- **Reusing short flags the child uses.** Long, namespaced flags only
  for wrapper config; reserve shorts for the child.

---

## One-screen start-from-scratch checklist

```
ARGV
[ ] Wrapper flags long & namespaced (--mywrap-*); shorts reserved for child
[ ] `--` is honored as end-of-options and stops your parsing
[ ] Documented shape: mywrap [WRAPPER] verb [-- CHILD-ARGS...]
[ ] Unknown flag before `--` is an error; after `--` is forwarded

CONFIG
[ ] Precedence: flag > env (MYWRAP_*) > project > $XDG_CONFIG_HOME > system > default
[ ] All wrapper env vars share one MYWRAP_ prefix
[ ] MYWRAP_CHILD_BIN overrides binary resolution

PROCESS
[ ] Default to execvp; spawn only when post-processing is required
[ ] If spawn: forward INT, TERM, QUIT, HUP, TSTP, CONT, USR1, USR2, WINCH
[ ] Exit = child's; signal-death = 128+N; re-raise on self for fidelity
[ ] Resolved child path logged under --mywrap-trace

RESOLUTION
[ ] $MYWRAP_CHILD_BIN -> config -> PATH -> bundled
[ ] Missing -> 127 with helpful message; not executable -> 126
[ ] If installed under child's name: PATH-strip OR MYWRAP_REENTRY guard

SUBCOMMANDS
[ ] Pick ONE plugin model (PATH-dispatch / longest-match / managed / reserved-verb)
[ ] Plugins cannot override built-ins
[ ] Pass verb as argv[1] to helper; export $MYWRAP for callbacks if useful

UX
[ ] --help shows wrapper opts + how to reach child help
[ ] --version prints wrapper version AND child version + resolved path
[ ] Wrapper diagnostics -> stderr; child stdout/stderr untouched
[ ] Completions for wrapper flags; defer to child for child flags

EXIT CODES
[ ] 0 ok; 2 usage; 64-78 sysexits (BSD, optional) for wrapper; 126/127 exec problems; 128+N signal
[ ] Document which ranges are "wrapper said no" vs "child said no"

TESTS
[ ] Spawner abstraction + stub child (golden argv snapshots)
[ ] --help / --version snapshot tests
[ ] Exit-code + signal-propagation matrix
[ ] Config precedence table tests
[ ] PATH-resolution + recursion-guard tests

DO NOT
[ ] parse the full child grammar
[ ] greedily consume flags you don't own
[ ] swallow the child's exit code
[ ] mix wrapper logs into child stdout
[ ] duplicate features the child already provides
```

---

## Single default rule — if you remember only one thing

`wrapper [wrapper-flags] -- inner...` · wrapper flags only before `--`
· pass inner argv unchanged · prefer `exec` unless you need
supervision · forward signals · propagate exit faithfully · resolve
via explicit override then `PATH` · reserve a distinct
plugin/subcommand namespace.

---

## References

### Specs & standards

- POSIX Utility Syntax Guidelines —
  <https://pubs.opengroup.org/onlinepubs/9699919799/basedefs/V1_chap12.html>
- POSIX `execvp` —
  <https://pubs.opengroup.org/onlinepubs/9699919799/functions/execvp.html>
- POSIX `exec` —
  <https://pubs.opengroup.org/onlinepubs/9799919799/functions/exec.html>
- POSIX `wait` —
  <https://pubs.opengroup.org/onlinepubs/9699919799/functions/wait.html>
- POSIX `xargs` (127 convention) —
  <https://pubs.opengroup.org/onlinepubs/009695399/utilities/xargs.html>
- GNU getopt / argument syntax —
  <https://www.gnu.org/software/libc/manual/html_node/Argument-Syntax.html>
- Bash exit status —
  <https://www.gnu.org/s/bash/manual/html_node/Exit-Status.html>
- BSD `sysexits.h` (Linux man) —
  <https://man7.org/linux/man-pages/man3/sysexits.h.3head.html>
- BSD `sysexits.h` (FreeBSD man) —
  <https://man.freebsd.org/cgi/man.cgi?query=sysexits>
- Wikipedia: Exit status —
  <https://en.wikipedia.org/wiki/Exit_status>

### Design guidelines

- Command Line Interface Guidelines (clig.dev) —
  <https://clig.dev/>
- 12 Factor CLI Apps — Jeff Dickey —
  <https://medium.com/@jdxcode/12-factor-cli-apps-dd3c227a0e46>
- The Twelve-Factor App — Config —
  <https://12factor.net/config>

### Process model, signals, PTY

- veithen.io: SIGTERM propagation in wrappers —
  <https://veithen.io/2014/11/16/sigterm-propagation.html>
- Baeldung: SIGINT propagation parent/child —
  <https://www.baeldung.com/linux/signal-propagation>
- R. Koucha: SIGWINCH & PTY handling —
  <http://www.rkoucha.fr/tech_corner/sigwinch.html>
- sudo manpage —
  <https://www.sudo.ws/docs/man/sudo.man/>

### Subcommand / plugin conventions

- Cargo external tools / custom subcommands —
  <https://doc.rust-lang.org/cargo/reference/external-tools.html>
- Git: How to integrate new subcommands —
  <https://git.github.io/htmldocs/howto/new-command.html>
- git-help docs —
  <https://git-scm.com/docs/git-help>
- Kubernetes: Extend kubectl with plugins —
  <https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/>
- GitHub Docs: Creating GitHub CLI extensions —
  <https://docs.github.com/en/github-cli/github-cli/creating-github-cli-extensions>
- gh extension manual —
  <https://cli.github.com/manual/gh_extension>
- mise getting started —
  <https://mise.jdx.dev/getting-started.html>
- GNU env invocation —
  <https://www.gnu.org/software/coreutils/manual/html_node/env-invocation.html>
- GNU time invocation —
  <https://www.gnu.org/software/time/manual/html_node/Invoking-time.html>

### Shim pattern

- Deep dive: how pyenv works (shim pattern) —
  <https://www.mungingdata.com/python/how-pyenv-works-shims/>
- pyenv shim interception pattern (readoss) —
  <https://readoss.com/en/pyenv/pyenv/shim-interception-pattern-pyenv-hijacks-python-commands>
- pyenv infinite-loop failure mode (issue #2696) —
  <https://github.com/pyenv/pyenv/issues/2696>
- mise vs asdf —
  <https://mac.install.guide/mise/mise-vs-asdf>
