---
digest-of: tech/languages/zig/project-bootstrap-spec
last-synced: 2026-07-09
source-files:
  - README.md
  - runbook.md
  - 00-toolchain-and-layout.md
  - 01-quality-gates.md
  - cli-project.md
  - library-project.md
token-estimate: 780
---

# AGENTS

## Scope

Zig binding of the general `tech/programming/project-bootstrap/` shelf: the once-per-project Zig
setup that takes an empty repo to a scaffolded, buildable, gated project ready for feature work. It
**overlays** the general spine (repo, license, governance, dev env, CI, security) and never restates
it; it owns only the Zig ecosystem choices and the two implementation-kind orderings (CLI, library).
Shipping prebuilt/cross-compiled binaries and publishing/tagging are release-phase, out of scope.

## Key Points

- **Scaffold:** `zig init` in the project dir creates `build.zig`, `build.zig.zon`, and `src/`.
  Current templates emit both an exe (`src/main.zig`) and a library module (`src/root.zig`) wired
  into `build.zig`; keep whichever the project needs and drop the other. There is no `--lib` flag —
  exe-vs-lib is expressed by which build steps you keep, not by init. With anyzig the first init
  must name a version (`zig <version> init`) since no `build.zig.zon` exists yet to infer from.
- **`build.zig`:** a normal Zig program (`build` fn taking `*std.Build`) that declares the build
  graph — modules, executables, the `test` step, dependencies. Imperative, not static config; this
  is where `addExecutable` / `addModule` and the `zig build run` / `zig build test` steps live.
- **`build.zig.zon`:** the ZON package manifest. At bootstrap it owns `.name`, `.version`,
  `.minimum_zig_version`, `.dependencies` (each with `url` + `hash`, added via `zig fetch --save`),
  and `.paths`. Keep minimal; add deps as needed.
- **Version pin:** Zig moves fast (pre-1.0), so pinning is essential. Pin in two places that must
  agree — `.minimum_zig_version` in `build.zig.zon` (in-tree, lets anyzig resolve the compiler) and
  the **Nix devShell** installing matching `zig` + `zls` so local and CI share one toolchain
  (`tools/nix/templates/zig`). If using anyzig, the devShell provides anyzig and the pin lives in
  `build.zig.zon`.
- **Layout:** default `zig init` layout (`src/main.zig` and/or `src/root.zig` plus the two
  manifests) is enough; grow `src/` into modules as needed, no enforced deeper convention. Bootstrap
  owns getting a project that `zig build` succeeds on.
- **Quality gates (all compiler built-ins):** `zig fmt --check .` (canonical formatter, no config
  knobs); `zig build test` (test runner ships in the compiler, `test { ... }` blocks live beside
  code; `zig test <file>` runs one file). No third-party linter — the compiler is the linter: unused
  locals/params are errors, Debug/ReleaseSafe insert runtime safety checks, so building cleanly is
  itself a gate. Wire `zig fmt --check` + `zig build test` into pre-commit and a task runner so
  local and CI invocations are identical.
- **Security baseline:** no `cargo-audit` equivalent; general baseline still applies — secrets
  hygiene, pinned dependency content hashes in `build.zig.zon` (tampering detectable), OpenSSF
  Scorecard.
- **CLI kind:** keep the `addExecutable` step so `zig build run` works, drop `root.zig` if pure CLI;
  arg parsing reads `std.process.args`/`argsAlloc` directly (no stdlib `clap`) or adds a community
  parser via `zig fetch --save`; map errors to exit status early (return an error union from `main`
  or `std.process.exit(code)`); confirm run + test steps.
- **Library kind:** keep `src/root.zig` as public entry, drop `main.zig` if pure library; export via
  `b.addModule("<name>", ...)` (the module, not a flag, defines the library); set `.name`,
  `.version`, `.paths` in `build.zig.zon` as the consumable contract; `test { ... }` blocks gate the
  public API. Consumers add it with `zig fetch --save` (records a hash) and import via
  `dependency(...).module("<name>")`.
- **Automation:** no dedicated `bootstrap-zig` cog skill yet — run `zig init` manually. Cross-domain
  skills apply: `bootstrap-nix`, `bootstrap-precommit`, `bootstrap-taskrunner`, `bootstrap-ci`
  (general `07-automation-with-cog.md`).

## Source Map

| Topic                                                           | File                         |
| --------------------------------------------------------------- | ---------------------------- |
| Binding index, how-to-use, implementation-kinds list, related   | `README.md`                  |
| Ordered Zig overlay steps (the _what_/_in what order_)          | `runbook.md`                 |
| `zig init`, `build.zig` + `build.zig.zon`, layout, pin + Nix    | `00-toolchain-and-layout.md` |
| `zig fmt` / `zig build test` / compile-time safety + pre-commit | `01-quality-gates.md`        |
| CLI bootstrap ordering (exe step, args, exit codes, run/test)   | `cli-project.md`             |
| Library bootstrap ordering (module export, manifest, consumers) | `library-project.md`         |

## Maintenance Notes

- General spine: `../../../programming/project-bootstrap/`. Nix devShell template:
  `../../../tools/nix/templates/zig/`. Compiler resolution: `../anyzig-workflow.md`; broader Zig
  refs: `../README.md`.
- `web-service.md` and other implementation kinds are declared followups; add them (and refresh
  `source-files`) when they land.
- Zig is pre-1.0 and moves fast — re-verify `zig init` behavior, manifest keys, and the built-in
  gates against upstream on a cadence when regenerating.
- No conflicts among the current source files.
  </content>
  </invoke>
