# 00 — Toolchain & layout

The Zig ecosystem choices for a fresh project: how to scaffold it, what the two manifest files own,
how to pin the compiler, and how the Nix devShell hosts the toolchain.

## Scaffold the project

`zig init` scaffolds a buildable project in the current directory:

```bash
zig init
```

It creates `build.zig`, `build.zig.zon`, and a `src/` tree. Current Zig templates emit both an
executable (`src/main.zig`) and a library module (`src/root.zig`) wired into `build.zig`; you keep
whichever the project needs and drop the other. There is no separate `--lib` flag — the exe-vs-lib
choice is expressed by which build steps you keep in `build.zig`, not by the init command.

If you resolve the compiler with anyzig, the very first `init` must name a version because there is
no `build.zig.zon` yet to infer from:

```bash
zig <version> init
```

See the [anyzig workflow](../anyzig-workflow.md) for version resolution details.

## `build.zig` — the build script

`build.zig` is a normal Zig program (a `build` function taking `*std.Build`) that declares the build
graph: modules, executables, the `test` step, and dependencies pulled from `build.zig.zon`. It is
imperative Zig, not a static config file — that is where the exe and library steps (`addExecutable`,
`addModule`) are defined and where `zig build run` / `zig build test` get their steps.

## `build.zig.zon` — the package manifest

`build.zig.zon` is the ZON (Zig Object Notation) manifest. At bootstrap it owns:

- `.name` and `.version` — package identity.
- `.minimum_zig_version` — the compiler version the project targets (see pinning below).
- `.dependencies` — external packages, each with a `url` + `hash`. Add these with
  `zig fetch --save <url>`, which resolves the hash and writes the entry for you.
- `.paths` — the files included when the package is consumed.

Keep it minimal at bootstrap; add dependencies as the project needs them.

## Version pinning + Nix

Zig moves fast and is not yet 1.0, so pinning the compiler is essential, not optional. Pin it in two
places that must agree:

- `.minimum_zig_version` in `build.zig.zon` records the version in-tree (and lets anyzig resolve the
  compiler from the project) — see the [anyzig workflow](../anyzig-workflow.md).
- The **Nix devShell** installs the matching `zig` (and `zls`) so local and CI share one toolchain —
  see [nix/templates/zig](../../../tools/nix/templates/zig/). This closes the "works on my machine"
  gap before any code is written.

If you use anyzig instead of a Nix-pinned `zig`, the devShell still provides anyzig and the pin
lives in `build.zig.zon`.

## Layout

The default `zig init` layout (`src/main.zig` and/or `src/root.zig`, plus the two manifests) is
enough to start. Grow `src/` into modules as the project needs; there is no enforced deeper
convention. Bootstrap owns getting a project that `zig build` succeeds on.

## Automation

Zig has no dedicated `bootstrap-zig` cog skill yet — run `zig init` manually. The cross-domain
skills still apply (`bootstrap-nix`, `bootstrap-precommit`, `bootstrap-taskrunner`, `bootstrap-ci`);
see
[general 07 — Automation with cog](../../../programming/project-bootstrap/07-automation-with-cog.md).
