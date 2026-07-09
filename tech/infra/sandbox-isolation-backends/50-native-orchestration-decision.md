# Native devcontainer parsing vs a heavyweight orchestrator under crun --krun

The runtime backend (libkrun via `crun --krun`, rootless Podman, KVM-class boundary) decides _how a
container is isolated_. Above it sits an **orchestration layer**: something that reads a
`devcontainer.json`, composes layers, expands variables, and runs lifecycle hooks. This note is
about that layer, and it argues one principle: on a `crun --krun` runtime, parse the config yourself
and drive lifecycle with argv-vector `exec` — do not delegate to a heavyweight devcontainer
orchestrator.

## The structural incompatibility

The obvious shortcut is to delegate to the reference orchestrator (Microsoft's `@devcontainers/cli`)
for parsing, substitution, lifecycle, features, and build, keeping your own code only for the thin
runtime adapter. Under `crun --krun` this does not work, and it fails for a structural reason, not a
tuning one.

That orchestrator keeps a container alive by installing a **keep-alive shim** as the container
entrypoint: a multi-line `sh -c` blob that traps signals and blocks. That blob has to traverse the
libkrun host-to-guest argv path **at container creation time**, before any `exec` channel exists.
And a multi-line `sh -c` payload is exactly the shape the libkrun newline bug mangles — the first
line runs, every subsequent line arrives at the guest shell with a stray `n` fused onto its first
token, so the shim dies with `necho: not found` and the container never comes up. See
[60-podman-libkrun-operational-notes.md](./60-podman-libkrun-operational-notes.md) for the full
repro and mechanism.

The consequences are worth stating precisely:

- The failure is **image-independent**. It is not about the base image, the `remoteUser`, or any
  config key. `up` fails at container creation for every image, because the shim itself cannot
  survive the argv path.
- There is **no configuration that disables the shim**. The shim _is_ how the orchestrator keeps its
  long-lived shell server alive for every later operation. You cannot keep the orchestrator and drop
  the blob.
- Runtime-selection tricks do not help. The failing layer is runtime _startup_, not runtime
  _selection_, so forcing the krun runtime by a different mechanism changes nothing.

So as long as the runtime is `crun --krun` and the libkrun newline path is unfixed upstream, a
shim-based orchestrator cannot bring a container up. This holds until either an upstream libkrun fix
lands or you swap the runtime — the latter defeating the entire reason for choosing this backend.

## The principle: parse natively, exec by argv vector

Parse `devcontainer.json` yourself and drive lifecycle with argv-vector `exec`, not shell-blob
entrypoints. Concretely:

- Read and merge the config with a small native parser (a `jq`-based pass is enough for the keys
  most configs actually use).
- Start the container on the **image's own entrypoint**. Do not inject a keep-alive shell shim.
- Run every lifecycle hook and every command into the sandbox as a **`podman exec` argv vector**,
  after the container is up. The newline bug lives on the container-creation argv path; it does
  **not** affect argv-vector `exec` on a running container.

This is not a workaround forced by the bug — it is a smaller, more legible design that happens to
also be immune to it. You own only the parse, the substitution pass, and the lifecycle dispatch; the
runtime, the OCI spec, and `podman exec` semantics stay upstream.

## The bug-immune-shape invariant

State the guarantee as an invariant the whole codebase upholds:

> **Never generate a `podman run --runtime krun … --entrypoint /bin/sh -c '<multi-line script>'`
> invocation.**

That single shape is what trips the libkrun newline bug. An adapter that only ever issues
single-line / argv-vector `exec` is immune by construction — it never reaches the broken
host-to-guest decode path. Because the invariant is enforced socially rather than by a type system,
back it with three cheap, layered checks:

- **Code review.** Any new `--entrypoint` override, or any helper that constructs `podman run` argv,
  must justify that its payload is single-line.
- **A doctor / health probe.** Scan the resolved `podman run` argv for the disallowed shape against
  a known-good fixture and fail loud on regression.
- **An optional pre-commit lint.** A grep-class rule rejecting commits that introduce a literal
  `--entrypoint … sh … -c` near `--runtime krun`.

The load-bearing property is that container startup uses the image's entrypoint and every command
into the microVM is an argv vector. Every change to the adapter must preserve it.

## The one real gap: variable substitution

Not delegating to the upstream orchestrator costs you exactly one capability that configs genuinely
lean on: **variable substitution**. The devcontainer spec lets a config interpolate host-environment
and workspace tokens, and a native parser has to expand them itself, in one pass, after layer merge
and before any `podman` invocation.

The bounded set most configs use:

| Pattern                           | Source                           | Typical use                                                        |
| --------------------------------- | -------------------------------- | ------------------------------------------------------------------ |
| `${localEnv:VAR}`                 | a host environment variable      | `remoteUser`, volume names, mount sources/targets, env passthrough |
| `${containerEnv:VAR}`             | the container's own environment  | composing `remoteEnv` values such as `PATH`                        |
| `${localWorkspaceFolderBasename}` | basename of the workspace folder | the container `name` field                                         |

Implementation shape: one helper that walks the resolved JSON, applies the substitutions, and
returns the expanded config to the adapter. It is a small, bounded amount of work — a helper plus
tests, not a subsystem. Keep it in-process; do **not** reintroduce an out-of-process substituter
(e.g. the upstream `read-configuration`) as a workaround, since that drags back the orchestrator
concepts you deliberately shed. Extend the helper when a config surfaces a spec corner (nested
`${...}`, other workspace tokens) that it does not yet cover.

## Why the features ecosystem is not a loss

The usual argument for adopting the upstream orchestrator is its **features ecosystem** — OCI
artifacts that install toolchains into a container at build time. That argument evaporates when your
toolchains are **baked into images and composed layers** instead. Hand-curated build layers do what
`features:` would do, without the fetch-and-install machinery and without needing the orchestrator
at all. Treat a features resolver as catalog-only: build it if and when a concrete config genuinely
needs a community feature you cannot bake into a layer — never speculatively.

## Net

On a `crun --krun` backend, a shim-based orchestrator is not merely heavyweight, it is structurally
unusable: its keep-alive blob is the exact shape the libkrun newline bug mangles at creation time.
Parse the config natively, start on the image entrypoint, exec by argv vector, and hold the
bug-immune-shape invariant with review plus a probe. The only real gap — variable substitution — is
a small, bounded helper, and the features ecosystem you give up is unnecessary once toolchains live
in the images.
